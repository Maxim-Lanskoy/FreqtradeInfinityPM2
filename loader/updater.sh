#!/usr/bin/env python
# coding: utf-8

import json
import requests
import os
import sys
import time
import re
import subprocess
from pathlib import Path
from urllib.request import urlopen
from datetime import datetime as dt
from dotenv import load_dotenv
import shutil

# Load environment variables from ../.env for general settings
env_path = Path('..') / '.env'
load_dotenv(dotenv_path=env_path)

# Retrieve the exchanges list from the main .env file
exchanges = os.getenv('EXCHANGES').split(",")

# Paths to various files
path_local_blacklist_base = 'user_data/'
path_private_blacklist_base = 'user_data/'
path_strategy = 'user_data/strategies/'

# Paths for additional files
path_pairlist_general = 'user_data/pairlist-volume-'
path_pairlist_general_suffix = '-usdt.json'
path_trading_mode_spot = 'user_data/trading_mode-spot.json'
path_trading_mode_futures = 'user_data/trading_mode-futures.json'

# Paths to strategy files
path_strategy4 = Path(path_strategy + 'NostalgiaForInfinityX4.py')
path_strategy5 = Path(path_strategy + 'NostalgiaForInfinityX5.py')
path_strategy_c = Path(path_strategy + 'NostalgiaForCustom.py')

# Local variables
restart_required = False
ft_update = False

# Configurable update options
update_ft = True
update_x4 = True
update_x5 = True
update_xC = True

messagetext = 'Performed updates:\n'

print("\n🚀 Starting updater...\n")

####################################
# STRATEGY UPDATER
####################################

def update_strategy_file(update_enabled, remote_url, local_path, strategy_name):
    global messagetext
    global restart_required
    if not update_enabled:
        print(f'ℹ️ Updates for {strategy_name} are disabled.\n')
        return

    try:
        remote_strat = urlopen(remote_url).read().decode('utf-8')
        remote_strat_version_match = re.search('return "v(.+?)"', remote_strat)

        if remote_strat_version_match:
            remote_strat_version = remote_strat_version_match.group(1)
            print(f'📥 Downloaded remote {strategy_name} version {remote_strat_version} from Github.')
        else:
            print(f'❌ Error: Could not find the version in the downloaded content for {strategy_name}.\n')
            return

    except Exception as e:
        print(f'❌ Error downloading {strategy_name} from Github: {e}.')
        return

    try:
        with open(local_path, 'r') as local_strat:
            local_strat = local_strat.read()
            local_strat_version_match = re.search('return "v(.+?)"', local_strat)

            if local_strat_version_match:
                local_strat_version = local_strat_version_match.group(1)
                print(f'📄 Loaded local {strategy_name} version {local_strat_version}.')
            else:
                print(f'❌ Error: Could not find the version in the local file for {strategy_name}.')
                return

    except FileNotFoundError:
        print(f'❌ Local {strategy_name} file not found. Please check the path.\n')
        return
    except Exception as e:
        print(f'❌ Error: {e}')
        return

    if remote_strat_version == local_strat_version:
        print(f'✅ {strategy_name} is already up to date.\n')
    else:
        print(f'⬆️ New version of {strategy_name} available.')
        restart_required = True
        try:
            with open(local_path, 'w') as f:
                f.write(remote_strat)
                new_strat_version_match = re.search('return "v(.+?)"', remote_strat)
                if new_strat_version_match:
                    new_strat_version = new_strat_version_match.group(1)
                    print(f'✅ Updated {strategy_name} to version {new_strat_version}.\n')
                    messagetext += f'🔹 {strategy_name} updated to v{new_strat_version} from v{local_strat_version}\n'
                else:
                    print(f'❌ Could not determine the new version after update for {strategy_name}.')
        except Exception as e:
            print(f'❌ Error: {e}')

# Update strategies
print("🔄 Checking for strategy updates...")
update_strategy_file(update_x4, 'https://raw.githubusercontent.com/iterativv/NostalgiaForInfinity/main/NostalgiaForInfinityX4.py', path_strategy4, 'NFIX4')
update_strategy_file(update_x5, 'https://raw.githubusercontent.com/iterativv/NostalgiaForInfinity/main/experimental/NostalgiaForInfinityX5.py', path_strategy5, 'NFIX5')
update_strategy_file(update_xC, 'https://raw.githubusercontent.com/Maxim-Lanskoy/FreqtradeInfinityPM2/loader/loader/user_data/strategies/NostalgiaForCustom.py', path_strategy_c, 'NFI Custom')

####################################
# BLACKLIST UPDATER
####################################

def update_blacklist(exchange):
    path_local_blacklist = path_local_blacklist_base + 'blacklist-' + exchange.lower() + '.json'
    path_private_blacklist = path_private_blacklist_base + 'blacklist-private.json'
    path_local_blacklist = Path(path_local_blacklist)
    path_private_blacklist = Path(path_private_blacklist)
    global messagetext
    global restart_required

    try:
        url_latest_bl = 'https://raw.githubusercontent.com/iterativv/NostalgiaForInfinity/main/configs/blacklist-' + exchange.lower() + '.json'
        response = requests.get(url_latest_bl)
        json_text = response.text
        json_text = "\n".join(line for line in json_text.split("\n") if not line.strip().startswith("//"))
        latest_bl = json.loads(json_text)
        print(f'📥 Downloaded remote blacklist for {exchange}.')
    except Exception as e:
        print(f'❌ Error downloading blacklist for {exchange}: {e}')
        exit(1)

    try:
        with open(path_local_blacklist, 'r') as file:
            now_bl = json.load(file)
            print(f'📄 Loaded local blacklist for {exchange}.')
    except FileNotFoundError:
        now_bl = {}
        print(f'⚠️ Local blacklist for {exchange} not found.')
    
    try:
        with open(path_private_blacklist, "r") as file:
            json_text = file.read()
        json_text = "\n".join(line for line in json_text.split("\n") if not line.strip().startswith("//"))
        private = json.loads(json_text)
        print(f'📄 Loaded private blacklist for {exchange}.')
    except FileNotFoundError:
        print(f'⚠️ Private blacklist for {exchange} not found. Creating an empty private blacklist.')
        private = {"exchange": {"pair_blacklist": ["(|)/.*"]}}
        with open(path_private_blacklist, 'w') as file:
            json.dump(private, file, indent=4)
        print(f'✅ Created new private blacklist for {exchange}.')

    latestprivate = {
        'exchange': {
            'pair_blacklist': latest_bl['exchange']['pair_blacklist'] + private['exchange']['pair_blacklist']
        }
    }

    if latestprivate != now_bl:
        with open(path_local_blacklist, 'w') as file:
            json.dump(latestprivate, file, indent=4)
        restart_required = True
        messagetext += f'🔹 Blacklist for {exchange} updated\n'
        print(f'✅ Blacklist for {exchange} updated.\n')
    else:
        print(f'✅ Blacklist for {exchange} is up to date.\n')

print("🔄 Checking for blacklist updates...")
for exchange in exchanges:
    print(f'📋 Updating blacklist for {exchange}')
    update_blacklist(exchange)

####################################
# ADDITIONAL FILES UPDATER
####################################

def update_file(url, local_path, description):
    global messagetext
    global restart_required

    try:
        response = requests.get(url)
        with open(local_path, 'w') as file:
            file.write(response.text)
        print(f'📥 {description} downloaded successfully.')
        messagetext += f'🔹 {description} updated\n'
        restart_required = True
    except Exception as e:
        print(f'❌ Error downloading {description}: {e}')
    print()

print("🔄 Updating additional configuration files...")

####################################
# PAIRLISTS UPDATER
####################################

for exchange in exchanges:
    print(f'📋 Updating pairlists for {exchange}')
    exchange_pairlist_path = path_pairlist_general + exchange.lower() + path_pairlist_general_suffix
    update_file(f'https://raw.githubusercontent.com/iterativv/NostalgiaForInfinity/main/configs/pairlist-volume-{exchange.lower()}-usdt.json', exchange_pairlist_path, f'Pairlists Volume {exchange} USDT')

# Update the trading mode files
update_file('https://raw.githubusercontent.com/iterativv/NostalgiaForInfinity/main/configs/trading_mode-spot.json', path_trading_mode_spot, 'Trading Mode Spot')
update_file('https://raw.githubusercontent.com/iterativv/NostalgiaForInfinity/main/configs/trading_mode-futures.json', path_trading_mode_futures, 'Trading Mode Futures')

####################################
# FREQTRADE UPDATER
####################################

def execute_command(command):
    output = subprocess.check_output(command, shell=True, text=True)
    return output

print("🔄 Checking for Freqtrade updates...")
if update_ft:
    datetoday = str(dt.now())[8:10]

    try:
        with open('last_update.txt', 'r') as file:
            for line in file:
                if line.startswith('last_checked_date='):
                    last_checked_date = line.strip().split('=')[1]
                    print(f'📄 Loaded last update date from last_update.txt.')
                # Skip lines that are comments or unrelated to updater logic
                if line.startswith("#") or line.strip() == "" or "python_installed_by_script" in line:
                    continue
    except FileNotFoundError:
        print(f'⚠️ last_update.txt not found. Creating it...')
        with open('last_update.txt', 'w') as f:
            f.write(f"last_checked_date={int(datetoday) - 1}\n")
        last_checked_date = str(int(datetoday) - 1)
    except Exception as e:
        print(f'❌ Error: {e}')

    if datetoday != last_checked_date:
        command = 'freqtrade --version'
        try:
            output = execute_command(command)
        except Exception as e:
            print(f'❌ Error executing Freqtrade version check: {e}')
            output = 'no version found'

        if "WARNING" not in output:
            matches = re.search(r'"version": "(.*?)"', output)
            old_ft_version = matches.group(1) if matches else ""
            print(f'📄 Current Freqtrade version: {old_ft_version}')

            # Stop pm2 service for the current exchange
            subprocess.run(f'pm2 stop Freqtrade-{exchange}', shell=True)
            time.sleep(10)

            # Update Freqtrade (assuming a virtualenv setup)
            subprocess.run('pip install --upgrade freqtrade', shell=True)
            time.sleep(30)

            output = execute_command(command)
            matches = re.search(r'"version": "(.*?)"', output)
            new_ft_version = matches.group(1) if matches else ""
            print(f'📄 New Freqtrade version: {new_ft_version}')

            if new_ft_version != old_ft_version:
                print(f'⬆️ New version detected: {new_ft_version}')
                messagetext += f'🔹 Freqtrade updated to {new_ft_version}\n'
                restart_required = True
            else:
                print(f'✅ Freqtrade is already up to date.')

            # Update last_checked_date in last_update.txt
            with open('last_update.txt', 'w') as f:
                f.write(f"last_checked_date={datetoday}\n")
    else:
        print(f'✅ Freqtrade updates already checked today. Skipping until tomorrow.\n')
else:
    print(f'ℹ️ Updates for Freqtrade are disabled.')

####################################
# REGENERATE EXCHANGE FILES
####################################

def load_env_file(env_file_path):
    """
    Load environment variables from a given .env file path, clearing previous ones.
    """
    for key in list(os.environ.keys()):
        if key.startswith('FREQTRADE__'):
            del os.environ[key]  # Remove any existing environment variables

    if env_file_path.exists():
        print(f"Loading environment variables from {env_file_path}")
        load_dotenv(dotenv_path=env_file_path, override=True)
        print(f"✅ Loaded environment variables from {env_file_path}")
    else:
        print(f"❌ ERROR: Environment file {env_file_path} not found!")
        sys.exit(1)

def fix_json_syntax(json_file_path):
    try:
        with open(json_file_path, 'r') as file:
            json_content = file.read()
        
        # Remove trailing commas before closing curly braces or brackets
        json_content = re.sub(r',\s*}', '}', json_content)
        json_content = re.sub(r',\s*]', ']', json_content)

        with open(json_file_path, 'w') as file:
            file.write(json_content)
    except Exception as e:
        print(f"❌ Error fixing JSON syntax in {json_file_path}: {e}")

def generate_files_for_exchange(exchange, user_data_dir):
    """
    Generate configuration files for a given exchange.
    """
    exchange_lower = exchange.lower()
    
    print(f"🔄 Generating files for exchange {exchange}")

    # Load environment variables for this exchange
    load_env_file(Path(f'../.env.{exchange_lower}'))
    
    required_vars = [
        "FREQTRADE__TELEGRAM__CHAT_ID",
        "FREQTRADE__TELEGRAM__TOKEN",
        "FREQTRADE__EXCHANGE__NAME",
        "FREQTRADE__EXCHANGE__KEY",
        "FREQTRADE__EXCHANGE__SECRET",
        "FREQTRADE__API_SERVER__ENABLED",
        "FREQTRADE__STRATEGY_FILE_NAME",
        "FREQTRADE__TRADING_MODE_TYPE"
    ]
    
    for var in required_vars:
        if not os.getenv(var):
            print(f"❌ ERROR: {var} is not set!")
            sys.exit(1)
        else:
            print(f"✅ {var} is set to '{os.getenv(var)}'")

    # Generate secrets-config-{exchange_lower}.json
    secrets_config_template = "secrets-config-with-password.json" if os.getenv('FREQTRADE__EXCHANGE__PASSWORD') else "secrets-config.json"
    envsubst_cmd = f'envsubst < {user_data_dir}/{secrets_config_template} > {user_data_dir}/secrets-config-{exchange_lower}.tmp.json'
    subprocess.run(envsubst_cmd, shell=True)

    fix_json_syntax(f"{user_data_dir}/secrets-config-{exchange_lower}.tmp.json")
    shutil.move(f"{user_data_dir}/secrets-config-{exchange_lower}.tmp.json", f"{user_data_dir}/secrets-config-{exchange_lower}.json")

    # Generate nostalgia-general-{exchange_lower}.json
    envsubst_cmd = f'envsubst < {user_data_dir}/nostalgia-general.json > {user_data_dir}/nostalgia-general-{exchange_lower}.tmp.json'
    subprocess.run(envsubst_cmd, shell=True)

    fix_json_syntax(f"{user_data_dir}/nostalgia-general-{exchange_lower}.tmp.json")
    shutil.move(f"{user_data_dir}/nostalgia-general-{exchange_lower}.tmp.json", f"{user_data_dir}/nostalgia-general-{exchange_lower}.json")

    print(f"✅ Generated files for exchange {exchange}")

print("🔄 Generating updated configuration files for each exchange...")

user_data_dir = './user_data'  # Define your user data directory path

for exchange in exchanges:
    generate_files_for_exchange(exchange, user_data_dir)

print("🎉 All files have been generated successfully!")

####################################
# NOTIFICATION VIA TELEGRAM AND RESTART LOGIC
####################################

print(f'💥 Restart required. Scheduling restart for all exchanges...')
minute = int(str(dt.now())[15:16])

# Decide on wait time based on the current minute
if minute in [0, 5]:
    print(f'🕐 Waiting 150 seconds...\n')
    time.sleep(150)
elif minute in [1, 6]:
    print(f'🕐 Waiting 90 seconds...\n')
    time.sleep(90)
elif minute in [2, 7]:
    print(f'🕐 Waiting 30 seconds...\n')
    time.sleep(30)
elif minute in [3, 8]:
    print(f'🕐 No waiting time\n')
elif minute in [4, 9]:
    print(f'🕐 Waiting 210 seconds...\n')
    time.sleep(210)
else:
    print(f'❌ Unexpected scheduling issue\n')

# Iterate through each exchange for restarts and notifications
for exchange in exchanges:
    # Clear the environment variables to avoid carryover
    os.environ.pop('FREQTRADE__TELEGRAM__TOKEN', None)
    os.environ.pop('FREQTRADE__TELEGRAM__CHAT_ID', None)

    # Reload environment variables for the specific exchange
    load_env_file(Path(f'../.env.{exchange.lower()}'))

    # Retrieve the Telegram API key and chat ID for the current exchange
    telegram_api_key = os.getenv('FREQTRADE__TELEGRAM__TOKEN')
    telegram_chat_id = os.getenv('FREQTRADE__TELEGRAM__CHAT_ID')

    # Debug: Print Telegram API Key and Chat ID for each exchange
    print(f"🔍 Debug for {exchange}:")
    print(f"    - Telegram API Key: {telegram_api_key}")
    print(f"    - Telegram Chat ID: {telegram_chat_id}")

    if not telegram_api_key or not telegram_chat_id:
        print(f"❌ Error: 'FREQTRADE__TELEGRAM__TOKEN' or 'FREQTRADE__TELEGRAM__CHAT_ID' is not set in the .env file for {exchange}.")
        continue

    # Restart the specific exchange's Freqtrade process using pm2
    subprocess.run(f'pm2 restart Freqtrade-{exchange}', shell=True)

    print(f"🔄 Restarted Freqtrade for {exchange}. Sending notification...")

    # Reload environment variables again before sending the notification
    load_env_file(Path(f'../.env.{exchange.lower()}'))
    telegram_api_key = os.getenv('FREQTRADE__TELEGRAM__TOKEN')
    telegram_chat_id = os.getenv('FREQTRADE__TELEGRAM__CHAT_ID')

    url = f"https://api.telegram.org/bot{telegram_api_key}/sendMessage?chat_id={telegram_chat_id}&text={messagetext}&parse_mode=HTML"
    response = requests.get(url)
    
    if response.ok:
        print(f"✅ Notification sent successfully for {exchange}.")
    else:
        print(f"❌ Failed to send notification for {exchange}. Response: {response.text}")

print("\n🎉 Updater finished successfully!")
