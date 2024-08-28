#!/bin/bash

# Load the main environment variables from the .env file located one level up
set -o allexport
while IFS='=' read -r key value; do
    if [[ ! -z "$key" && "$key" != \#* ]]; then
        key=$(echo $key | xargs)
        value=$(echo $value | xargs)
        echo "Loading $key=$value"
        export "$key=$value"
    fi
done < ../.env
set +o allexport

# Check if FREQTRADE__TRADING_MODE_TYPE is set
if [ -z "$FREQTRADE__TRADING_MODE_TYPE" ]; then
    echo "❌ ERROR: FREQTRADE__TRADING_MODE_TYPE is not set!"
    exit 1
else
    echo "✅ FREQTRADE__TRADING_MODE_TYPE is set to '$FREQTRADE__TRADING_MODE_TYPE'"
fi

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
            echo "Loading $key=$value for $EXCHANGE"
            export "$key=$value"
        fi
    done < ../.env.$EXCHANGE_LOWER
    set +o allexport

    # Check if trading mode config file is correctly generated
    echo "Generating trading mode config for ${FREQTRADE__TRADING_MODE_TYPE}..."
    envsubst < user_data/trading_mode-template.json > user_data/trading_mode-${FREQTRADE__TRADING_MODE_TYPE}.json
    if [ ! -f "user_data/trading_mode-${FREQTRADE__TRADING_MODE_TYPE}.json" ]; then
        echo "❌ ERROR: trading_mode-${FREQTRADE__TRADING_MODE_TYPE}.json not created!"
        exit 1
    fi

    # Generate the secrets-config-$EXCHANGE_LOWER.json by replacing placeholders in the template
    envsubst < user_data/secrets-config.json > user_data/secrets-config-$EXCHANGE_LOWER.json

    # Generate the nostalgia-general-$EXCHANGE_LOWER.json by replacing placeholders in the template
    sed "s/secrets-config.json/secrets-config-$EXCHANGE_LOWER.json/g" user_data/nostalgia-general.json > user_data/nostalgia-general-$EXCHANGE_LOWER.json

    # Start Freqtrade with environment variables and using the exchange-specific config files
    pm2 start freqtrade --name "Freqtrade-$EXCHANGE" --interpreter python3 -- trade --config user_data/nostalgia-general-$EXCHANGE_LOWER.json --strategy "${FREQTRADE__STRATEGY_FILE_NAME}" --db-url "sqlite:///user_data/Nostalgy-${FREQTRADE__EXCHANGE__NAME}-${FREQTRADE__TRADING_MODE_TYPE}-DB.sqlite"

    echo "✅ Started Freqtrade for $EXCHANGE."
done
