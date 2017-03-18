#!/usr/bin/env bash
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

if [[ $TO_BUILD == "boxemup" ]]
    then
    sudo apt-get update -qq
    pip install -q requests
else
    sudo add-apt-repository ppa:jonathonf/automake -y
    sudo apt-get update -qq
    sudo apt-get install -qq automake-1.15
fi
sudo apt-get install -qq p7zip-full realpath
