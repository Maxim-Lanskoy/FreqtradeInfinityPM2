#!/bin/bash

# Load environment variables from .env file located one level up
export $(grep -v '^#' ../.env | xargs)

# Start Freqtrade with environment variables
freqtrade trade --config user_data/nostalgia-general.json --strategy "${FREQTRADE__STRATEGY_FILE_NAME}" --db-url "sqlite:///user_data/Nostalgy-${FREQTRADE__EXCHANGE__NAME}-${FREQTRADE__TRADING_MODE_TYPE}-DB.sqlite"
