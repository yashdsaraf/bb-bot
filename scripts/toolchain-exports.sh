##SET TOOLCHAIN NAMES
TOOLCHAINDIR="$(realpath `dirname $0`/toolchains)"
ARM=$TOOLCHAINDIR/armhf-uClibc
#ARM=$TOOLCHAINDIR/arm-uClibc
ARM64=$TOOLCHAINDIR/aarch64-glibc
MIPS64=$TOOLCHAINDIR/mips64el-glibc
MIPS=$TOOLCHAINDIR/mipsel-uClibc
MIPSEB=$TOOLCHAINDIR/mipseb-glibc
X86=$TOOLCHAINDIR/i586-uClibc
X86_64=$TOOLCHAINDIR/x86_64-uClibc
ARMMUSL=$TOOLCHAINDIR/arm-musl
X86MUSL=$TOOLCHAINDIR/i586-musl
MIPSMUSL=$TOOLCHAINDIR/mipsel-musl
export ARM64 ARM MIPSEB MIPS MIPS64 X86 X86_64 ARMMUSL X86MUSL MIPSMUSL
