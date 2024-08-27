#!/bin/bash

# Load the main environment variables from the .env file located one level up
export $(grep -v '^#' ../.env | xargs)

# Extract the list of exchanges from the .env file
EXCHANGES=$(grep '^EXCHANGES=' ../.env | cut -d '=' -f 2 | tr -d ' ')

# Convert comma-separated EXCHANGES string to an array
IFS=',' read -r -a EXCHANGE_ARRAY <<< "$EXCHANGES"

for EXCHANGE in "${EXCHANGE_ARRAY[@]}"
do
    echo "🔄 Starting Freqtrade for $EXCHANGE..."

    # Load the environment variables for the specific exchange
    export $(grep -v '^#' ../.env.$EXCHANGE | xargs)

    # Generate the secrets-config-$EXCHANGE.json by replacing placeholders in the template
    envsubst < user_data/secrets-config.json > user_data/secrets-config-$EXCHANGE.json

    # Generate the nostalgia-general-$EXCHANGE.json by replacing placeholders in the template
    sed "s/secrets-config.json/secrets-config-$EXCHANGE.json/g" user_data/nostalgia-general.json > user_data/nostalgia-general-$EXCHANGE.json

    # Start Freqtrade with environment variables and using the exchange-specific config files
    pm2 start freqtrade --name "Freqtrade-$EXCHANGE" -- trade --config user_data/nostalgia-general-$EXCHANGE.json --strategy "${FREQTRADE__STRATEGY_FILE_NAME}" --db-url "sqlite:///user_data/Nostalgy-${FREQTRADE__EXCHANGE__NAME}-${FREQTRADE__TRADING_MODE_TYPE}-DB.sqlite"

    echo "✅ Started Freqtrade for $EXCHANGE."
done
