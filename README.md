# Freqtrade automation with NostalgiaForIntinityX strategy 🚀

[![Freqtrade CI](https://github.com/freqtrade/freqtrade/workflows/Freqtrade%20CI/badge.svg)](https://github.com/freqtrade/freqtrade/actions/)
[![DOI](https://joss.theoj.org/papers/10.21105/joss.04864/status.svg)](https://doi.org/10.21105/joss.04864)
[![Coverage Status](https://coveralls.io/repos/github/freqtrade/freqtrade/badge.svg?branch=develop&service=github)](https://coveralls.io/github/freqtrade/freqtrade?branch=develop)
[![Documentation](https://readthedocs.org/projects/freqtrade/badge/)](https://www.freqtrade.io)
[![Maintainability](https://api.codeclimate.com/v1/badges/5737e6d668200b7518ff/maintainability)](https://codeclimate.com/github/freqtrade/freqtrade/maintainability)

Automated scripts to set up and manage Freqtrade trading bots across multiple exchanges using [PM2](https://pm2.keymetrics.io). This repository provides a workflow for deploying and updating Freqtrade bots on various environments including MacOS (`brew`), Linux (`apt`), and Oracle Linux (`dnf`).

### **NostalgiaForIntinityX** 🌟
This project extensively uses the [NostalgiaForInfinityX](https://github.com/iterativv/NostalgiaForInfinity) strategy by **iterativv**, a popular trading strategy for the Freqtrade crypto bot, known for its robust performance in various market conditions. The strategy is continuously updated and optimized for better results. You can learn more about this strategy and its updates directly from the [repository](https://github.com/iterativv/NostalgiaForInfinity).

## Supported Exchange Marketplaces 🌐

Read the [exchange specific notes](docs/exchanges.md) to learn about configurations needed for each exchange, or if [trading with leverage](docs/leverage.md) is needed.

- [x] [Binance](https://www.binance.com/)
- [x] [Gate.io](https://www.gate.io/)
- [x] [KuCoin](https://www.kucoin.com/)
- [x] [MEXC](https://www.mexc.com)
- [ ] [Potentially many others](https://github.com/ccxt/ccxt/) _(cannot guarantee they will work)_

## Quick Start 🚀

Follow these steps to quickly set up and start using the Freqtrade management scripts:

1. **Clone the Repository** 📂
   ```bash
   git clone git@github.com:Maxim-Lanskoy/FreqtradeInfinityPM2.git
   cd freqtrade-management-automation
   ```

2. **Install Freqtrade from Scratch** 💻
   ```bash
   ./setup.sh -i
   ```
   This works for Debian, Ubuntu, Oracle Limux or macOS.

3. **Activate Virtual Environment** 🌐
   ```bash
   source .venv/bin/activate
   ```

4. **Install or Update Dependencies** 🔧


   Use the `setup-pm2.sh` script to install or update automation-related dependencies (`npm` and `pm2`):
   ```bash
   ./loader/setup-pm2.sh
   ```

5. **Start Your Bots** 🚀


   Start the Freqtrade bots for each exchange using the `start-pm2.sh` script:
   ```bash
   ./start-pm2.sh
   ```

6. **Update Bots and Configurations** 🔄


   Run the `updater.sh` script to check for updates and apply them:
   ```bash
   ./updater.sh
   ```
   This script updates strategies, blacklists, and other configuration files and restarts bots if necessary.

## **Uninstallation** 🗑️


   To uninstall specific for this repo dependencies, like Node.js, npm, and PM2, run the `uninstall.sh` script:
   ```bash
   ./loader/uninstall.sh
   ```

## Basic Bot Usage 📘

### Telegram RPC Commands

Telegram is not mandatory but provides a convenient way to control your bot. More details and the full command list can be found in the [documentation](https://www.freqtrade.io/en/latest/telegram-usage/).

- `/start`: Starts the trader.
- `/stop`: Stops the trader.
- `/profit [<n>]`: Lists cumulative profit from all finished trades, over the last n days.
- `/balance`: Show account balance per currency.
- `/help`: Show help message.
- `/version`: Show version.

## Development Branches 🌿

The project is currently set up in two main branches:

- `develop`: This branch is a fork from the original [Freqtrade](https://github.com/freqtrade/freqtrade) repository.
- `loader`: Contains scripts for installing additional dependencies and automation scripts for the [NostalgiaForInfinityX](https://github.com/iterativv/NostalgiaForInfinity) strategy.

## Requirements 📋

### Minimum Hardware Requirements

To run this bot, we recommend using a cloud instance or machine with the following minimum specifications:

- **Hardware**: 2GB RAM, 1GB disk space, 2vCPU.
- **Software**: 
  - [Python >= 3.9](http://docs.python-guide.org/en/latest/starting/installation/)
  - [pip](https://pip.pypa.io/en/stable/installing/)
  - [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - [TA-Lib](https://ta-lib.github.io/ta-lib-python/)
  - [virtualenv](https://virtualenv.pypa.io/en/stable/installation.html)
  - [gettext (envsubst)](https://man7.org/linux/man-pages/man1/envsubst.1.html)
  - [nodejs](https://nodejs.org/en)
  - [npm](https://www.npmjs.com)
  - [pm2](https://pm2.keymetrics.io)

## Troubleshooting 🛠️

For troubleshooting, please refer to the [installation documentation page](https://www.freqtrade.io/en/stable/installation/) or the [NostalgiaForInfinityX strategy page](https://github.com/iterativv/NostalgiaForInfinity).
