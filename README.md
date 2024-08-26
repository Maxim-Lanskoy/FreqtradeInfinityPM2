[![Freqtrade CI](https://github.com/freqtrade/freqtrade/workflows/Freqtrade%20CI/badge.svg)](https://github.com/freqtrade/freqtrade/actions/)
[![DOI](https://joss.theoj.org/papers/10.21105/joss.04864/status.svg)](https://doi.org/10.21105/joss.04864)
[![Coverage Status](https://coveralls.io/repos/github/freqtrade/freqtrade/badge.svg?branch=develop&service=github)](https://coveralls.io/github/freqtrade/freqtrade?branch=develop)
[![Documentation](https://readthedocs.org/projects/freqtrade/badge/)](https://www.freqtrade.io)
[![Maintainability](https://api.codeclimate.com/v1/badges/5737e6d668200b7518ff/maintainability)](https://codeclimate.com/github/freqtrade/freqtrade/maintainability)

Freqtrade is a free and open source crypto trading bot written in Python. It is designed to support all major exchanges and be controlled via Telegram or webUI. It contains backtesting, plotting and money management tools as well as strategy optimization by machine learning.

## Supported Exchange marketplaces

Read the [exchange specific notes](docs/exchanges.md) to learn about configurations needed for each exchange, or if [trading with leverage](docs/leverage.md) needed.

- [X] [Binance](https://www.binance.com/)
- [X] [Gate.io](https://www.gate.io/)
- [X] [Kucoin](https://www.kucoin.com/)
- [X] [MEXC](https://www.mexc.com)
- [ ] [potentially many others](https://github.com/ccxt/ccxt/). _(I cannot guarantee they will work)_

## Quick start

- Clone repository with `git clone git@github.com:Maxim-Lanskoy/FreqtradeInfinityPM2.git`.
- Install Freqtrade from scratch - `./setup.sh -i` (Debian, Ubuntu or MacOS).
- Use `./loader/setup-pm2.sh` to install or update automation related dependencies - `npm` and `pm2`.
- Virtual environment - you must run `source .venv/bin/activate` to activate your environment.

For troubleshooting please refer to the [installation documentation page](https://www.freqtrade.io/en/stable/installation/) or [NostalgiaToInfinity strategy page](https://github.com/iterativv/NostalgiaForInfinity).

To uninstall nodejs, npm and pm2 from your setup you can run `./loader/uninstall.sh`.

## Basic Usage

### Telegram RPC commands

Telegram is not mandatory. However, this is a great way to control your bot. More details and the full command list on the [documentation](https://www.freqtrade.io/en/latest/telegram-usage/)

- `/start`: Starts the trader.
- `/stop`: Stops the trader.
- `/profit [<n>]`: Lists cumulative profit from all finished trades, over the last n days.
- `/balance`: Show account balance per currency.
- `/help`: Show help message.
- `/version`: Show version.

## Development branches

The project is currently setup in two main branches:

- `develop` - This branch is a fork from original [Freqtrade](https://github.com/freqtrade/freqtrade) repository.
- `loader` - Contains scripts for installing additional dependencies and automation scripts for [NostalgiaForInfinity](https://github.com/iterativv/NostalgiaForInfinity) strategy.

## Requirements

### Minimum hardware required

To run this bot we recommend you a cloud instance or machine with a minimum of:

- `Hardware` - Minimal system requirements: 2GB RAM, 1GB disk space, 2vCPU.
- `Software` - [Python >= 3.9](http://docs.python-guide.org/en/latest/starting/installation/), [pip](https://pip.pypa.io/en/stable/installing/), [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git), [TA-Lib](https://ta-lib.github.io/ta-lib-python/), [virtualenv](https://virtualenv.pypa.io/en/stable/installation.html), [nodejs](https://nodejs.org/en), [npm](https://www.npmjs.com), [pm2](https://pm2.keymetrics.io)
