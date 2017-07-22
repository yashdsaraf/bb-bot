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

##SET TOOLCHAIN NAMES
ARM=$TOOLCHAINDIR/armhf-uClibc
#ARM=$TOOLCHAINDIR/arm-uClibc
ARM64=$TOOLCHAINDIR/aarch64-uClibc
MIPS64=$TOOLCHAINDIR/mips64el-uClibc
MIPS=$TOOLCHAINDIR/mipsel-uClibc
MIPSEB=$TOOLCHAINDIR/mipseb-uClibc
X86=$TOOLCHAINDIR/i586-uClibc
X86_64=$TOOLCHAINDIR/x86_64-uClibc
ARMMUSL=$TOOLCHAINDIR/arm-musl
X86MUSL=$TOOLCHAINDIR/i586-musl
MIPSMUSL=$TOOLCHAINDIR/mipsel-musl
export ARM64 ARM MIPSEB MIPS MIPS64 X86 X86_64 ARMMUSL X86MUSL MIPSMUSL
