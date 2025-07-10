# SPDX-License-Identifier: AGPL-3.0-or-later
"""Processors for engine-type: ``online``

"""
# pylint: disable=use-dict-literal

from timeit import default_timer
import asyncio
import ssl
import httpx

import searx.network
from searx.utils import gen_useragent
from searx.exceptions import (
    SearxEngineAccessDeniedException,
    SearxEngineCaptchaException,
    SearxEngineTooManyRequestsException,
)
from searx.metrics.error_recorder import count_error
from .abstract import EngineProcessor


def default_request_params():
    """Default request parameters for ``online`` engines."""
    return {
        # fmt: off
        'method': 'GET',
        'headers': {},
        'data': {},
        'url': '',
        'cookies': {},
        'auth': None
        # fmt: on
    }


class OnlineProcessor(EngineProcessor):
    """Processor class for ``online`` engines."""

    engine_type = 'online'

    def initialize(self):
        # set timeout for all HTTP requests
        searx.network.set_timeout_for_thread(self.engine.timeout, start_time=default_timer())
        # reset the HTTP total time
        searx.network.reset_time_for_thread()
        # set the network
        searx.network.set_context_network_name(self.engine_name)
        super().initialize()

    def get_params(self, search_query, engine_category):
        """Returns a set of :ref:`request params <engine request online>` or ``None``
        if request is not supported.
        """
        params = super().get_params(search_query, engine_category)
        if params is None:
            return None

        # add default params
        params.update(default_request_params())

        # add an user agent
        params['headers']['User-Agent'] = gen_useragent()

        # add Accept-Language header
        if self.engine.send_accept_language_header and search_query.locale:
            ac_lang = search_query.locale.language
            if search_query.locale.territory:
                ac_lang = "%s-%s,%s;q=0.9,*;q=0.5" % (
                    search_query.locale.language,
                    search_query.locale.territory,
                    search_query.locale.language,
                )
            params['headers']['Accept-Language'] = ac_lang

        self.logger.debug('HTTP Accept-Language: %s', params['headers'].get('Accept-Language', ''))
        return params

    def _send_http_request(self, params):
        # create dictionary which contain all
        # information about the request
        request_args = dict(headers=params['headers'], cookies=params['cookies'], auth=params['auth'])

        # verify
        # if not None, it overrides the verify value defined in the network.
        # use False to accept any server certificate
        # use a path to file to specify a server certificate
        verify = params.get('verify')
        if verify is not None:
            request_args['verify'] = params['verify']

        # max_redirects
        max_redirects = params.get('max_redirects')
        if max_redirects:
            request_args['max_redirects'] = max_redirects

        # allow_redirects
        if 'allow_redirects' in params:
            request_args['allow_redirects'] = params['allow_redirects']

        # soft_max_redirects
        soft_max_redirects = params.get('soft_max_redirects', max_redirects or 0)

        # raise_for_status
        request_args['raise_for_httperror'] = params.get('raise_for_httperror', True)

        # specific type of request (GET or POST)
        if params['method'] == 'GET':
            req = searx.network.get
        else:
            req = searx.network.post

        request_args['data'] = params['data']

        # send the request
        response = req(params['url'], **request_args)

        # check soft limit of the redirect count
        if len(response.history) > soft_max_redirects:
            # unexpected redirect : record an error
            # but the engine might still return valid results.
            status_code = str(response.status_code or '')
            reason = response.reason_phrase or ''
            hostname = response.url.host
            count_error(
                self.engine_name,
                '{} redirects, maximum: {}'.format(len(response.history), soft_max_redirects),
                (status_code, reason, hostname),
                secondary=True,
            )

        return response

    def _search_basic(self, query, params):
        # update request parameters dependent on
        # search-engine (contained in engines folder)
        self.engine.request(query, params)

        # ignoring empty urls
        if not params['url']:
            return None

        # send request
        response = self._send_http_request(params)

        # parse the response
        response.search_params = params
        return self.engine.response(response)

    def search(self, query, params, result_container, start_time, timeout_limit):
        # set timeout for all HTTP requests
        searx.network.set_timeout_for_thread(timeout_limit, start_time=start_time)
        # reset the HTTP total time
        searx.network.reset_time_for_thread()
        # set the network
        searx.network.set_context_network_name(self.engine_name)

        try:
            # send requests and parse the results
            search_results = self._search_basic(query, params)
            self.extend_container(result_container, start_time, search_results)
        except ssl.SSLError as e:
            # requests timeout (connect or read)
            self.handle_exception(result_container, e, suspend=True)
            self.logger.error("SSLError {}, verify={}".format(e, searx.network.get_network(self.engine_name).verify))
        except (httpx.TimeoutException, asyncio.TimeoutError) as e:
            # requests timeout (connect or read)
            self.handle_exception(result_container, e, suspend=True)
            self.logger.error(
                "HTTP requests timeout (search duration : {0} s, timeout: {1} s) : {2}".format(
                    default_timer() - start_time, timeout_limit, e.__class__.__name__
                )
            )
        except (httpx.HTTPError, httpx.StreamError) as e:
            # other requests exception
            self.handle_exception(result_container, e, suspend=True)
            self.logger.exception(
                "requests exception (search duration : {0} s, timeout: {1} s) : {2}".format(
                    default_timer() - start_time, timeout_limit, e
                )
            )
        except SearxEngineCaptchaException as e:
            self.handle_exception(result_container, e, suspend=True)
            self.logger.exception('CAPTCHA')
        except SearxEngineTooManyRequestsException as e:
            self.handle_exception(result_container, e, suspend=True)
            self.logger.exception('Too many requests')
        except SearxEngineAccessDeniedException as e:
            self.handle_exception(result_container, e, suspend=True)
            self.logger.exception('SearXNG is blocked')
        except Exception as e:  # pylint: disable=broad-except
            self.handle_exception(result_container, e)
            self.logger.exception('exception : {0}'.format(e))

    def get_default_tests(self):
        tests = {}

        tests['simple'] = {
            'matrix': {'query': ('life', 'computer')},
            'result_container': ['not_empty'],
        }

        if getattr(self.engine, 'paging', False):
            tests['paging'] = {
                'matrix': {'query': 'time', 'pageno': (1, 2, 3)},
                'result_container': ['not_empty'],
                'test': ['unique_results'],
            }
            if 'general' in self.engine.categories:
                # avoid documentation about HTML tags (<time> and <input type="time">)
                tests['paging']['matrix']['query'] = 'news'

        if getattr(self.engine, 'time_range', False):
            tests['time_range'] = {
                'matrix': {'query': 'news', 'time_range': (None, 'day')},
                'result_container': ['not_empty'],
                'test': ['unique_results'],
            }

        if getattr(self.engine, 'traits', False):
            tests['lang_fr'] = {
                'matrix': {'query': 'paris', 'lang': 'fr'},
                'result_container': ['not_empty', ('has_language', 'fr')],
            }
            tests['lang_en'] = {
                'matrix': {'query': 'paris', 'lang': 'en'},
                'result_container': ['not_empty', ('has_language', 'en')],
            }

        if getattr(self.engine, 'safesearch', False):
            tests['safesearch'] = {'matrix': {'query': 'porn', 'safesearch': (0, 2)}, 'test': ['unique_results']}

        return tests
