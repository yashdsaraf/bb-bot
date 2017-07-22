#!/usr/bin/env python
# Copyright 2017 Yash D. Saraf
# This file is part of BB-Bot.

# BB-Bot is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# BB-Bot is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with BB-Bot.  If not, see <http://www.gnu.org/licenses/>.

import requests
from termcolor import colored

from concurrent.futures import ThreadPoolExecutor
from os import environ, remove
import sys
from time import sleep
from zipfile import ZipFile


token = environ['TOKEN']
tag = environ['BUILD_TAG']
ver = environ['VER']
slug = environ['TRAVIS_REPO_SLUG']
url = 'https://api.github.com/repos/{:s}/releases/tags/{:s}'.format(slug, tag)

auth = (slug.split('/')[0], token) #Github username and OAuth token
archs = ('ARM', 'X86', 'MIPS')

def download(arch):
    file = 'Busybox-' + ver + '-' + arch + '.zip'
    print('Looking for ' + file + ' --')
    while True:
        response = requests.get(url, auth=auth)
        for asset in response.json():
            if asset['name'] == file:
                asset_url = asset['url']
                break
        else:
            sleep(5)
            print(colored('Still looking for ' + file + ' --', 'yellow'))
            continue
        break

    print(colored('Downloading ' + file + ' --', 'blue'))
    response = requests.get(asset_url, auth=auth, headers={'Accept': 'application/octet-stream'})

    if response.status_code == 302:
        response = requests.get(response.headers.get('location'), auth=auth)

    if response.status_code != 200:
        print(colored('Error ' + str(response.status_code) + ': ' + response.json()['message'], 'red'))
        sys.exit()

    with open(file, 'wb') as fd:
        for chunk in response.iter_content(chunk_size=128):
            fd.write(chunk)

    print(colored('Unzipping ' + file + ' --', 'blue'))
    with ZipFile(file) as zipfile:
        names = filter(lambda x: 'META-INF' not in x and '.sh' not in x, zipfile.namelist())
        zipfile.extractall('../bbx/Bins/' + arch.lower(), names)

    print(colored('Done with ' + file + '!', 'green'))
    remove(file)

print('Looking for the given tag --')
while True:
    response = requests.get(url, auth=auth)
    data = response.json()
    if response.status_code == 200:
        break
    sleep(5)
    print(colored('Still looking for the given tag --', 'yellow'))

url = data['url'] + '/assets'
print(colored('Tag found!', 'green'))

with ThreadPoolExecutor() as executor:
    executor.map(download, archs)
