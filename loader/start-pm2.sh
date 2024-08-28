#!/bin/bash

# Load the main environment variables from the .env file located one level up
set -o allexport
while IFS='=' read -r key value; do
    # Only export if key is not empty and doesn't start with a #
    if [[ ! -z "$key" && "$key" != \#* ]]; then
        # Remove leading and trailing spaces from key and value
        key=$(echo $key | xargs)
        value=$(echo $value | xargs)
        export "$key=$value"
    fi
done < ../.env
set +o allexport

# Extract the list of exchanges from the .env file
EXCHANGES=$(grep '^EXCHANGES=' ../.env | cut -d '=' -f 2 | tr -d ' ')

# Convert comma-separated EXCHANGES string to an array
IFS=',' read -r -a EXCHANGE_ARRAY <<< "$EXCHANGES"

for EXCHANGE in "${EXCHANGE_ARRAY[@]}"
do
    echo "🔄 Starting Freqtrade for $EXCHANGE..."

    # Convert the exchange name to lowercase for file access
    EXCHANGE_LOWER=$(echo "$EXCHANGE" | tr '[:upper:]' '[:lower:]')

    # Load the environment variables for the specific exchange (now using the lowercase filename)
    set -o allexport
    while IFS='=' read -r key value; do
        if [[ ! -z "$key" && "$key" != \#* ]]; then
            key=$(echo $key | xargs)
            value=$(echo $value | xargs)
            export "$key=$value"
        fi
    done < ../.env.$EXCHANGE_LOWER
    set +o allexport

    # Generate the secrets-config-$EXCHANGE_LOWER.json by replacing placeholders in the template
    envsubst < user_data/secrets-config.json > user_data/secrets-config-$EXCHANGE_LOWER.json

    # Generate the nostalgia-general-$EXCHANGE_LOWER.json by replacing placeholders in the template
    sed "s/secrets-config.json/secrets-config-$EXCHANGE_LOWER.json/g" user_data/nostalgia-general.json > user_data/nostalgia-general-$EXCHANGE_LOWER.json

    # Create the trading mode config file
    envsubst < user_data/trading_mode-template.json > user_data/trading_mode-${FREQTRADE__TRADING_MODE_TYPE}.json

    # Start Freqtrade with environment variables and using the exchange-specific config files
    pm2 start freqtrade --name "Freqtrade-$EXCHANGE" --interpreter python3 -- trade --config user_data/nostalgia-general-$EXCHANGE_LOWER.json --strategy "${FREQTRADE__STRATEGY_FILE_NAME}" --db-url "sqlite:///user_data/Nostalgy-${FREQTRADE__EXCHANGE__NAME}-${FREQTRADE__TRADING_MODE_TYPE}-DB.sqlite"

    echo "✅ Started Freqtrade for $EXCHANGE."
done
