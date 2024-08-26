#!/usr/bin/env python
# coding: utf-8

try:
    import json, requests, os, sys, time, re, subprocess
    from pathlib import Path
    from urllib.request import urlopen
    from datetime import datetime as dt

    print('\n\n####################################\n' + str(dt.now()) + '\n')
except ModuleNotFoundError as e:
    print(str(e) + '. Please install required dependencies.')
except ImportError as e:
    print(e)
else:
    print('All required dependencies successfully loaded.')

# Put in your telegram data here
telegram_api_key = ''
telegram_chat_id = ''

# Add the paths to your files
path_local_blacklist_base = 'user_data/'
path_private_blacklist_base = 'user_data/'
path_strategy = 'user_data/strategies/'

# Paths for additional files
path_pairlist_general = 'user_data/pairlist-volume-'
path_pairlist_general_suffix = '-usdt.json'
path_trading_mode_spot = 'user_data/trading_mode-spot.json'
path_trading_mode_futures = 'user_data/trading_mode-futures.json'

# Don't change anything here
path_strategy4 = path_strategy + 'NostalgiaForInfinityX4.py'
path_strategy5 = path_strategy + 'NostalgiaForInfinityX5.py'
path_strategy_c = path_strategy + 'NostalgiaForCustom.py'
path_strategy4 = Path(path_strategy4)
path_strategy5 = Path(path_strategy5)
path_strategy_c = Path(path_strategy_c)

# Local varuables used in the script
restart_required = False
ft_update = False

# Configurable update options, enabled exchanges list
exchanges = ['Binance', 'Kucoin', "GateIO", "MEXC"]
update_ft = True
update_x4 = True
update_x5 = True
update_xC = True

messagetext = 'Performed updates:\n'

####################################
# NFIX UPDATER
####################################

def update_strategy_file(update_enabled, remote_url, local_path, strategy_name):
    global messagetext
    global restart_required
    if not update_enabled:
        print(f'\U00002705 Updates for {strategy_name} are disabled.\n')
        return

    try:
        remote_strat = urlopen(remote_url).read().decode('utf-8')
        remote_strat_version = re.search('return "v(.+?)"', remote_strat).group(1)
        print(f'\U00002705 Remote {strategy_name} version {remote_strat_version} successfully downloaded from Github.')
    except Exception as e:
        print(f'\U0000274C Could not download remote {strategy_name} file from Github: {e}')
        return

    try:
        with open(local_path, 'r') as local_strat:
            local_strat = local_strat.read()
            local_strat_version = re.search('return "v(.+?)"', local_strat).group(1)
            print(f'\U00002705 Local {strategy_name} version {local_strat_version} file successfully loaded.')
    except FileNotFoundError:
        print(f'\U0000274C Could not load local {strategy_name} file. Please check path.\n')
        return
    except Exception as e:
        print(e)
        return

    if remote_strat_version == local_strat_version:
        print(f'\U00002705 Strategy {strategy_name} file is up to date.\n')
    else:
        print(f'\U0000274C New version of strategy {strategy_name} available.')
        restart_required = True
        try:
            with open(local_path, 'w') as f:
                f.write(remote_strat)
                new_strat_version = re.search('return "v(.+?)"', remote_strat).group(1)
                print(f'\U00002705 Updated {strategy_name} to version {new_strat_version}.\n')
        except AttributeError:
            print(f'\U0000274C Could not find version number of {strategy_name}.')
            new_strat_version = f'Unknown version of {strategy_name}'
        
        messagetext = messagetext + f'\U0001F539 {strategy_name} updated to v{new_strat_version} from v{local_strat_version}\n'

# NFIX4 UPDATER
update_strategy_file(update_x4, 'https://raw.githubusercontent.com/iterativv/NostalgiaForInfinity/main/NostalgiaForInfinityX4.py', path_strategy4, 'NFIX4')

# NFIX5 UPDATER
update_strategy_file(update_x5, 'https://raw.githubusercontent.com/iterativv/NostalgiaForInfinity/main/experimental/NostalgiaForInfinityX5.py', path_strategy5, 'NFIX5')

# NFIX CUSTOM UPDATER
update_strategy_file(update_xC, 'https://raw.githubusercontent.com/Maxim-Lanskoy/FreqtradeInfinityPM2/loader/user_data/strategies/NostalgiaForCustom.py', path_strategy_c, 'NFI Custom')

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
        print(f'\U00002705 Remote blacklist {exchange} successfully downloaded from Github.')
    except Exception as e:
        print(f'\U0000274C Could not download remote blacklist {exchange} from Github: {e}')
        exit(1)

    try:
        with open(path_local_blacklist, 'r') as file:
            now_bl = json.load(file)
            print(f'\U00002705 Local blacklist {exchange} successfully loaded.')
    except FileNotFoundError:
        now_bl = {}
        print(f'\U0000274C Could not load local blacklist {exchange}.')
    
    try:
        with open(path_private_blacklist, "r") as file:
            json_text = file.read()
        json_text = "\n".join(line for line in json_text.split("\n") if not line.strip().startswith("//"))
        private = json.loads(json_text)
        print(f'\U00002705 Private blacklist {exchange} successfully loaded.')
    except FileNotFoundError:
        print(f'\U0000274C Could not load private blacklist {exchange}.\nCreating empty private blacklist.')
        private = {"exchange": {"pair_blacklist": ["(|)/.*"]}}
        with open(path_private_blacklist, 'w') as file:
            json.dump(private, file, indent=4)
        print(f'\U00002705 Newly created private blacklist {exchange} successfully loaded.')

    latestprivate = {
        'exchange': {
            'pair_blacklist': latest_bl['exchange']['pair_blacklist'] + private['exchange']['pair_blacklist']
        }
    }

    if latestprivate != now_bl: 
        with open(path_local_blacklist, 'w') as file:
            json.dump(latestprivate, file, indent=4)
        restart_required = True
        messagetext = messagetext + f'\U0001F539 Blacklist {exchange} updated\n'
        print(f'\U000027A1 Blacklist {exchange}: Update available.\n')
    else:
        print(f'\U00002705 Blacklist {exchange} is up to date.\n')

for exchange in exchanges:
    print(f'BLACKLIST UPDATER {exchange}')
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
        print(f'\U00002705 {description} successfully downloaded from Github.')
        messagetext = messagetext + f'\U0001F539 {description} updated\n'
        restart_required = True
    except Exception as e:
        print(f'\U0000274C Could not download {description} from Github: {e}')
        
    print(f'\n')

####################################
# PAIRLISTS UPDATER
####################################

for exchange in exchanges:
    print(f'PAITLISTS UPDATER {exchange}')
    exchange_pairlist_path = path_pairlist_general + exchange.lower() + path_pairlist_general_suffix
    update_file('https://raw.githubusercontent.com/iterativv/NostalgiaForInfinity/main/configs/pairlist-volume-{exchange}-usdt.json', exchange_pairlist_path, 'Pairlists Volume {exchange} USDT')
    
# Update the trading mode files
update_file('https://raw.githubusercontent.com/iterativv/NostalgiaForInfinity/main/configs/trading_mode-spot.json', path_trading_mode_spot, 'Trading Mode Spot')
update_file('https://raw.githubusercontent.com/iterativv/NostalgiaForInfinity/main/configs/trading_mode-futures.json', path_trading_mode_futures, 'Trading Mode Futures')

####################################
# FREQTRADE UPDATER
####################################

def execute_command(command):
    output = subprocess.check_output(command, shell=True, text=True)
    return output

if update_ft:
    datetoday = str(dt.now())[8:10]

    try:
        with open('date.txt', 'r') as datefromfile:
            datefromfile = datefromfile.read()
            print(f'\U00002705 date.txt successfully loaded.')
    except FileNotFoundError:
        print(f'\U0000274C Could not load date.txt. Creating it...')
        with open('date.txt', 'w') as f:
            f.write(str(int(datetoday) - 1))
        with open('date.txt', 'r') as datefromfile:
            datefromfile = datefromfile.read()
    except Exception as e:
        print(e)

    if datetoday != datefromfile:
        command = 'freqtrade --version'
        try:
            output = execute_command(command)
        except Exception as e:
            print(e)
            output = 'no version found'

        if "WARNING" not in output:
            matches = re.search(r'"version": "(.*?)"', output)
            old_ft_version = matches.group(1) if matches else ""
            print(f'\U00002705 Old Freqtrade version: {old_ft_version}')

            # Stop pm2 service
            subprocess.run('pm2 stop FreqTrade', shell=True)
            time.sleep(10)

            # Update Freqtrade (assuming a virtualenv setup)
            subprocess.run('pip install --upgrade freqtrade', shell=True)

            time.sleep(30)

            output = execute_command(command)
            matches = re.search(r'"version": "(.*?)"', output)
            new_ft_version = matches.group(1) if matches else ""
            print(f'\U00002705 New Freqtrade version: {new_ft_version}')

            if new_ft_version != old_ft_version:
                print(f'\U0000274C New version detected: {new_ft_version}')
                messagetext = messagetext + f'\U0001F539 Freqtrade updated to {new_ft_version}\n'
                restart_required = True
            else:
                print(f'\U00002705 No new version for Freqtrade.')

            with open('date.txt', 'w') as f:
                f.write(datetoday)
    else:
        print(f'\U00002705 Already checked for updates for Freqtrade today. Skipping this step until tomorrow.')
else:
    print(f'\U00002705 Updates for Freqtrade are disabled.')

####################################
# NOTIFICATION VIA TELEGRAM
####################################

if restart_required:
    print(f'\n\U0001F4A5 Scheduling restart...')
    minute = int(str(dt.now())[15:16])

    if minute in [0, 5]:
        print(f'\U0001F551 wait 150 seconds\n')
        time.sleep(150)
    elif minute in [1, 6]:
        print(f'\U0001F551 wait 90 seconds\n')
        time.sleep(90)
    elif minute in [2, 7]:
        print(f'\U0001F551 wait 30 seconds\n')
        time.sleep(30)
    elif minute in [3, 8]:
        print(f'\U0001F551 no waiting time\n')
        time.sleep(0)
    elif minute in [4, 9]:
        print(f'\U0001F551 wait 210 seconds\n')
        time.sleep(210)
    else:
        print(f'\U0000274C something is wrong\n')

    # Restart pm2 service only once
    subprocess.run('pm2 restart FreqTrade', shell=True)

    print(messagetext)
    url = f"https://api.telegram.org/bot{telegram_api_key}/sendMessage?chat_id={telegram_chat_id}&text={messagetext}&parse_mode=HTML"
    print(requests.get(url).json())

else:
    print(f'\U00002705 No restart required.')
    restart_required = False
