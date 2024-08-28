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

# Load main environment variables from ../.env
env_path_main = Path('..') / '.env'
load_dotenv(dotenv_path=env_path_main)

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
# FUNCTION TO LOAD EXCHANGE-SPECIFIC ENVIRONMENT VARIABLES
####################################

def load_exchange_env(exchange):
    env_path = Path('..') / f'.env.{exchange.lower()}'
    load_dotenv(dotenv_path=env_path)
    print(f"✅ Loaded environment variables from .env.{exchange.lower()}")

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
        # Attempt to download the strategy from the given URL
        remote_strat = urlopen(remote_url).read().decode('utf-8')
        remote_strat_version_match = re.search('return "v(.+?)"', remote_strat)

        # Check if version pattern was found
        if remote_strat_version_match:
            remote_strat_version = remote_strat_version_match.group(1)
            print(f'📥 Downloaded remote {strategy_name} version {remote_strat_version} from Github.')
        else:
            print(f'❌ Error: Could not find the version in the downloaded content for {strategy_name}. Check the file content or URL.')
            return

    except Exception as e:
        print(f'❌ Error downloading {strategy_name} from Github: {e}.')
        return

    try:
        # Attempt to read the local strategy file
        with open(local_path, 'r') as local_strat:
            local_strat = local_strat.read()
            local_strat_version_match = re.search('return "v(.+?)"', local_strat)

            # Check if version pattern was found in the local file
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

    # Compare remote and local versions
    if remote_strat_version == local_strat_version:
        print(f'✅ {strategy_name} is already up to date.\n')
    else:
        print(f'⬆️ New version of {strategy_name} available.')
        restart_required = True
        try:
            with open(local_path, 'w') as f:
                f.write(remote_strat)
                new_strat_version = remote_strat_version
                print(f'✅ Updated {strategy_name} to version {new_strat_version}.\n')
        except Exception as e:
            print(f'❌ Error updating {strategy_name}: {e}')
            new_strat_version = f'Unknown version of {strategy_name}'
        
        messagetext += f'🔹 {strategy_name} updated to v{new_strat_version} from v{local_strat_version}\n'

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

            # Stop pm2 services based on exchange names
            for exchange in exchanges:
                pm2_name = f"Freqtrade-{exchange}"
                subprocess.run(f'pm2 stop {pm2_name}', shell=True)
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
        print(f'✅ Freqtrade updates already checked today. Skipping until tomorrow.')
else:
    print(f'ℹ️ Updates for Freqtrade are disabled.')

####################################
# NOTIFICATION VIA TELEGRAM AND RESTART PM2 PROCESS
####################################

if restart_required:
    print(f'\n💥 Restart required. Scheduling restart...')
    minute = int(str(dt.now())[15:16])

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
        time.sleep(0)
    elif minute in [4, 9]:
        print(f'🕐 Waiting 210 seconds...\n')
        time.sleep(210)
    else:
        print(f'❌ Unexpected scheduling issue\n')

    # Iterate through exchanges to restart each specific process and send notification
    for exchange in exchanges:
        load_exchange_env(exchange)  # Load exchange-specific environment variables
        telegram_api_key = os.getenv('FREQTRADE__TELEGRAM__TOKEN')
        telegram_chat_id = os.getenv('FREQTRADE__TELEGRAM__CHAT_ID')

        if not telegram_api_key or not telegram_chat_id:
            print(f"❌ Error: 'FREQTRADE__TELEGRAM__TOKEN' or 'FREQTRADE__TELEGRAM__CHAT_ID' is not set in the .env.{exchange.lower()} file.")
            continue

        # Restart the pm2 process for the specific exchange
        pm2_process_name = f"Freqtrade-{exchange.capitalize()}"
        subprocess.run(f'pm2 restart {pm2_process_name}', shell=True)

        # Send the Telegram notification for the specific exchange
        url = f"https://api.telegram.org/bot{telegram_api_key}/sendMessage?chat_id={telegram_chat_id}&text={messagetext}&parse_mode=HTML"
        response = requests.get(url)
        if response.ok:
            print(f"✅ Notification sent successfully for {exchange}.")
        else:
            print(f"❌ Failed to send notification for {exchange}. Response: {response.text}")

else:
    print(f'✅ No restart required.')
    restart_required = False

print("\n🎉 Updater finished successfully!")
