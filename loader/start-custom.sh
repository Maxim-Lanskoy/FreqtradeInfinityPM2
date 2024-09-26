#!/bin/bash

# Load environment variables for this exchange
source "../.env.bybit"

# Directly use the variables in the command
freqtrade trade \
    --config "./user_data/nostalgia-general-bybit.json" \
    --config "./user_data/trading_mode-futures.json" \
    --config "./user_data/pairlist-volume-bybit-usdt.json" \
    --config "./user_data/blacklist-bybit.json" \
    --config "./user_data/settings-config.json" \
    --config "./user_data/secrets-config-bybit.json" \
    --db-url "sqlite:///./user_data/Nostalgy-bybit-futures-DB.sqlite" \
    --strategy "NostalgiaForCustom"
