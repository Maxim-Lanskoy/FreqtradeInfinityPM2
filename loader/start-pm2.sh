#!/bin/bash

# Function to load environment variables from a file
load_env_file() {
    local env_file="$1"
    echo "Loading environment variables from $env_file"

    if [[ -f "$env_file" ]]; then
        # Read and export each line in the environment file
        while IFS='=' read -r key value; do
            # Skip empty lines and comments
            if [[ -n "$key" && "$key" != \#* ]]; then
                # Trim spaces around the key and value
                key=$(echo "$key" | xargs)
                value=$(echo "$value" | xargs)
                
                # Export the variable
                export "$key"="$value"
            fi
        done < "$env_file"
        echo "✅ Loaded environment variables from $env_file"
    else
        echo "❌ ERROR: Environment file $env_file not found!"
        exit 1
    fi
}

# Load the main environment variables from the .env file located one level up
load_env_file "../.env"

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
    load_env_file "../.env.$EXCHANGE_LOWER"

    # Check required environment variables are set
    REQUIRED_VARS=("FREQTRADE__TELEGRAM__CHAT_ID" "FREQTRADE__TELEGRAM__TOKEN" "FREQTRADE__EXCHANGE__NAME" "FREQTRADE__EXCHANGE__KEY" "FREQTRADE__EXCHANGE__SECRET" "FREQTRADE__API_SERVER__ENABLED" "FREQTRADE__STRATEGY_FILE_NAME" "FREQTRADE__TRADING_MODE_TYPE")
    
    for VAR in "${REQUIRED_VARS[@]}"; do
        if [ -z "${!VAR}" ]; then
            echo "❌ ERROR: $VAR is not set!"
            exit 1
        else
            echo "✅ $VAR is set to '${!VAR}'"
        fi
    done

    # Generate the secrets-config-$EXCHANGE_LOWER.json by replacing placeholders in the template
    if [ -n "$FREQTRADE__EXCHANGE__PASSWORD" ]; then
        # Include password in the config
        envsubst < user_data/secrets-config-with-password.json > user_data/secrets-config-$EXCHANGE_LOWER.json
    else
        # Exclude password in the config
        envsubst < user_data/secrets-config.json > user_data/secrets-config-$EXCHANGE_LOWER.json
    fi

    # Generate the nostalgia-general-$EXCHANGE_LOWER.json by replacing placeholders in the template
    envsubst < user_data/nostalgia-general.json > user_data/nostalgia-general-$EXCHANGE_LOWER.json

    # Start Freqtrade with environment variables and using the exchange-specific config files
    pm2 start freqtrade --name "Freqtrade-$EXCHANGE" --interpreter python3 -- trade --config user_data/nostalgia-general-$EXCHANGE_LOWER.json --strategy "${FREQTRADE__STRATEGY_FILE_NAME}" --db-url "sqlite:///user_data/Nostalgy-${FREQTRADE__EXCHANGE__NAME}-${FREQTRADE__TRADING_MODE_TYPE}-DB.sqlite"

    echo "✅ Started Freqtrade for $EXCHANGE."
done
