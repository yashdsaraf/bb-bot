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

import requests, sys
from concurrent.futures import ThreadPoolExecutor
from zipfile import ZipFile
from os import environ, remove
from time import sleep

token = environ['TOKEN']
tag = environ['BUILD_TAG']
ver = environ['VER']
slug = environ['TRAVIS_REPO_SLUG']
url = 'https://api.github.com/repos/{:s}/releases/tags/{:s}'.format(slug, tag)

auth = (slug.split('/')[0],token) #Github username and OAuth token
archs = ('ARM','X86','MIPS')

def download(arch):
    count = 0
    file = 'Busybox-' + ver + '-' + arch + '.zip'
    print('Downloading ' + file + '--')
    while True:
        response = requests.get(url, auth=auth)
        for asset in response.json():
            if asset['name'] == file:
                asset_url = asset['url']
                break
        else:
            sys.stdout.write('\r{:d}s'.format(count))
            sys.stdout.flush()
            count += 5
            sleep(5)
            continue
        print('')
        break
    response = requests.get(asset_url, auth=auth, headers={'Accept': 'application/octet-stream'})

    if response.status_code == 302:
        response = requests.get(response.headers.get('location'), auth=auth)
    elif response.status_code != 200:
        print('Error ' + str(response.status_code) + ': ' + response.json()['message'])
        sys.exit()

    with open(file, 'wb') as fd:
        for chunk in response.iter_content(chunk_size=128):
            fd.write(chunk)

    print('Unzipping ' + file + '--')
    with ZipFile(file) as zipfile:
        names = filter(lambda x: 'META-INF' not in x, zipfile.namelist())
        zipfile.extractall('../bbx/Bins/' + arch.lower(), names)

    remove(file)

print('Looking for the given tag--')
count = 0
while True:
    response = requests.get(url, auth=auth)
    data = response.json()
    if response.status_code == 200:
        break
    sys.stdout.write('\r{:d}s'.format(count))
    sys.stdout.flush()
    count += 5
    sleep(5)

print('')
url = data['url'] + '/assets'
print('Tag found!')

with ThreadPoolExecutor() as executor:
    executor.map(download, archs)
