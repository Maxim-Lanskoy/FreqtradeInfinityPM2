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

# Define the user data directory path
USER_DATA_DIR="./user_data"

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
        envsubst < "$USER_DATA_DIR/secrets-config-with-password.json" > "$USER_DATA_DIR/secrets-config-$EXCHANGE_LOWER.tmp.json"
    else
        # Exclude password in the config
        envsubst < "$USER_DATA_DIR/secrets-config.json" > "$USER_DATA_DIR/secrets-config-$EXCHANGE_LOWER.tmp.json"
    fi

    # Replace boolean strings 'true' and 'false' with actual booleans in JSON
    sed -e 's/"false"/false/g' -e 's/"true"/true/g' "$USER_DATA_DIR/secrets-config-$EXCHANGE_LOWER.tmp.json" > "$USER_DATA_DIR/secrets-config-$EXCHANGE_LOWER.json"
    rm "$USER_DATA_DIR/secrets-config-$EXCHANGE_LOWER.tmp.json"

    # Generate the nostalgia-general-$EXCHANGE_LOWER.json by replacing placeholders in the template
    envsubst < "$USER_DATA_DIR/nostalgia-general.json" > "$USER_DATA_DIR/nostalgia-general-$EXCHANGE_LOWER.tmp.json"

    # Replace boolean strings 'true' and 'false' with actual booleans in JSON
    sed -e 's/"false"/false/g' -e 's/"true"/true/g' "$USER_DATA_DIR/nostalgia-general-$EXCHANGE_LOWER.tmp.json" > "$USER_DATA_DIR/nostalgia-general-$EXCHANGE_LOWER.json"
    rm "$USER_DATA_DIR/nostalgia-general-$EXCHANGE_LOWER.tmp.json"

    # Output generated JSON for debugging
    echo "Generated secrets-config-$EXCHANGE_LOWER.json:"
    cat "$USER_DATA_DIR/secrets-config-$EXCHANGE_LOWER.json"

    echo "Generated nostalgia-general-$EXCHANGE_LOWER.json:"
    cat "$USER_DATA_DIR/nostalgia-general-$EXCHANGE_LOWER.json"

    # Validate JSON files using jq (ensure jq is installed)
    jq empty "$USER_DATA_DIR/secrets-config-$EXCHANGE_LOWER.json" || { echo "Invalid JSON in secrets-config-$EXCHANGE_LOWER.json"; exit 1; }
    jq empty "$USER_DATA_DIR/nostalgia-general-$EXCHANGE_LOWER.json" || { echo "Invalid JSON in nostalgia-general-$EXCHANGE_LOWER.json"; exit 1; }

    # **Updated PM2 Start Command**:
    pm2 start freqtrade --name "Freqtrade-$EXCHANGE" --interpreter python3 -- trade \
    --config "$USER_DATA_DIR/nostalgia-general-$EXCHANGE_LOWER.json" \
    --config "$USER_DATA_DIR/trading_mode-spot.json" \
    --config "$USER_DATA_DIR/pairlist-volume-binance-usdt.json" \
    --config "$USER_DATA_DIR/blacklist-binance.json" \
    --config "$USER_DATA_DIR/settings-config.json" \
    --config "$USER_DATA_DIR/secrets-config-$EXCHANGE_LOWER.json" \
    --strategy "${FREQTRADE__STRATEGY_FILE_NAME}" \
    --db-url "sqlite:///$USER_DATA_DIR/Nostalgy-${FREQTRADE__EXCHANGE__NAME}-${FREQTRADE__TRADING_MODE_TYPE}-DB.sqlite"

    echo "✅ Started Freqtrade for $EXCHANGE."
done
