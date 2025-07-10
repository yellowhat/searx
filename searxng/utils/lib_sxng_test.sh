#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later

test.help(){
    cat <<EOF
test.:
  yamllint  : lint YAML files (YAMLLINT_FILES)
  pylint    : lint ./searx, ./searxng_extra and ./tests
  pyright   : static type check of python sources (.dev or .ci)
  black     : check black code format
  unit      : run unit tests
  coverage  : run unit tests with coverage
  robot     : run robot test
  rst       : test .rst files incl. README.rst
  clean     : clean intermediate test stuff
EOF
}

if [ "$VERBOSE" = "1" ]; then
    TEST_NOSE2_VERBOSE="-vvv"
fi

test.yamllint() {
    build_msg TEST "[yamllint] \$YAMLLINT_FILES"
    pyenv.cmd yamllint --strict --format parsable "${YAMLLINT_FILES[@]}"
    dump_return $?
}

test.pylint() {
    (   set -e
        pyenv.activate
        PYLINT_OPTIONS="--rcfile .pylintrc"

        build_msg TEST "[pylint] ./searx/engines"
        # shellcheck disable=SC2086
        pylint ${PYLINT_OPTIONS} ${PYLINT_VERBOSE} \
            --additional-builtins="traits,supported_languages,language_aliases,logger,categories" \
            searx/engines

        build_msg TEST "[pylint] ./searx ./searxng_extra ./tests"
        # shellcheck disable=SC2086
        pylint ${PYLINT_OPTIONS} ${PYLINT_VERBOSE} \
               --ignore=searx/engines \
               searx searx/searxng.msg \
               searxng_extra searxng_extra/docs_prebuild \
               tests
    )
    dump_return $?
}

test.types.dev() {
    # use this pyright test for local tests in development / it suppress
    # warnings related to intentional monkey patching but gives good hints where
    # we need to work on SearXNG's typification.
    #
    # --> pyrightconfig.json

    build_msg TEST "[pyright/types] static type check of python sources"
    build_msg TEST "    --> typeCheckingMode: on"
    node.env.dev

    build_msg TEST "[pyright/types] suppress warnings related to intentional monkey patching"
    # We run Pyright in the virtual environment because pyright executes
    # "python" to determine the Python version.
    pyenv.cmd npx --no-install pyright -p pyrightconfig.json \
        | grep -E '\.py:[0-9]+:[0-9]+'\
        | grep -v '/engines/.*.py.* - warning: "logger" is not defined'\
        | grep -v '/plugins/.*.py.* - error: "logger" is not defined'\
        | grep -v '/engines/.*.py.* - warning: "supported_languages" is not defined' \
        | grep -v '/engines/.*.py.* - warning: "language_aliases" is not defined' \
        | grep -v '/engines/.*.py.* - warning: "categories" is not defined'
    # ignore exit value from pyright
    # dump_return ${PIPESTATUS[0]}
    return 0
}

test.types.ci() {
    # use this pyright test for CI / disables typeCheckingMode, needed as long
    # we do not have fixed all typification issues.
    #
    # --> pyrightconfig-ci.json

    build_msg TEST "[pyright] static type check of python sources"
    build_msg TEST "    --> typeCheckingMode: off !!!"
    node.env.dev

    build_msg TEST "[pyright] suppress warnings related to intentional monkey patching"
    # We run Pyright in the virtual environment because pyright executes
    # "python" to determine the Python version.
    pyenv.cmd npx --no-install pyright -p pyrightconfig-ci.json \
        | grep -E '\.py:[0-9]+:[0-9]+'\
        | grep -v '/engines/.*.py.* - warning: "logger" is not defined'\
        | grep -v '/plugins/.*.py.* - error: "logger" is not defined'\
        | grep -v '/engines/.*.py.* - warning: "supported_languages" is not defined' \
        | grep -v '/engines/.*.py.* - warning: "language_aliases" is not defined' \
        | grep -v '/engines/.*.py.* - warning: "categories" is not defined'
    # ignore exit value from pyright
    # dump_return ${PIPESTATUS[0]}
    return 0
}

test.black() {
    build_msg TEST "[black] \$BLACK_TARGETS"
    pyenv.cmd black --check --diff "${BLACK_OPTIONS[@]}" "${BLACK_TARGETS[@]}"
    dump_return $?
}

test.unit() {
    build_msg TEST 'tests/unit'
    # shellcheck disable=SC2086
    pyenv.cmd python -m nose2 ${TEST_NOSE2_VERBOSE} -s tests/unit
    dump_return $?
}

test.coverage() {
    build_msg TEST 'unit test coverage'
    (   set -e
        pyenv.activate
        # shellcheck disable=SC2086
        python -m nose2 ${TEST_NOSE2_VERBOSE} -C --log-capture --with-coverage --coverage searx -s tests/unit
        coverage report
        coverage html
    )
    dump_return $?
}

test.robot() {
    build_msg TEST 'robot'
    gecko.driver
    PYTHONPATH=. pyenv.cmd python -m tests.robot
    dump_return $?
}

test.rst() {
    build_msg TEST "[reST markup] ${RST_FILES[*]}"

    for rst in "${RST_FILES[@]}"; do
        pyenv.cmd rst2html --halt error "$rst" > /dev/null || die 42 "fix issue in $rst"
    done
}

test.themes() {
    build_msg TEST 'SearXNG themes'
    themes.test
    dump_return $?
}

test.pybabel() {
    TEST_BABEL_FOLDER="build/test/pybabel"
    build_msg TEST "[extract messages] pybabel"
    mkdir -p "${TEST_BABEL_FOLDER}"
    pyenv.cmd pybabel extract -F babel.cfg -o "${TEST_BABEL_FOLDER}/messages.pot" searx
}

test.clean() {
    build_msg CLEAN  "test stuff"
    rm -rf geckodriver.log .coverage coverage/
    dump_return $?
}
