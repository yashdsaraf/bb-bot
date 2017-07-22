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

import pysftp

from datetime import date
from os import environ
from os.path import abspath


hostname = 'frs.sourceforge.net'
username = 'rorschack'
_private_key = 'sf_private_key'
_private_key_password = environ['SF_PRIVATE_KEY_PASS']
release_path = '/home/frs/project/busybox-yds'
dir_name = date.today().strftime('%b-%d-%y')
local_release_path = abspath('../bbx/out')
cnopts = pysftp.CnOpts()
cnopts.hostkeys = None

with pysftp.Connection(hostname, username=username, private_key=_private_key, private_key_pass=_private_key_password, cnopts=cnopts) as sftp:
    with sftp.cd(release_path):
        if not sftp.exists(dir_name):
            sftp.mkdir(dir_name, mode='755')
        sftp.put_d(local_release_path, dir_name)
