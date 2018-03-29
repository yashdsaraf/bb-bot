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

set -e
export DATE="`date +'%d %b/%y'`"
cd "$(realpath `dirname $0`)"
echo -e "\n\nStarting BB-Bot build $BUILD_TAG ${TO_BUILD}\n\n"
TOOLCHAINDIR="$PWD/toolchains"
. ./toolchain-exports.sh
mkdir -p ../out ../bbx/out
if [[ $TO_BUILD == "boxemup" ]]
    then
    ./settags.sh
    ./download_files.py
else
    ./build-ssl.sh
    ./build-bb.sh
    ./update-bins.sh
    ./createtgz.sh
fi
./mkzip.sh
if [[ $TRAVIS_BRANCH == "master" ]]
    then
    ./sourceforge-release.py
fi
echo "Files to deploy --"
ls -lh ../bbx/out/*
