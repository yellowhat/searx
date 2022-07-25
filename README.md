# searx-heroku

Deploy [searx](https://searx.github.io/searx) on [heroku](https://heroku.com)

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/yellowhat/searx-heroku/tree/main)

## Requirements

* A (free) Heroku account

## Prevent downtime after periods of inactivity (30 mins)

* [easycron](https://easycron.com): use a (free) account with the cron expression `*/20 7-23 * * *`
* [cronjob](https://github.com/benbusby/whoogle-search#prevent-downtime-heroku-only)
