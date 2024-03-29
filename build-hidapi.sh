#!/usr/bin/env bash

# Convenience script to build hidapi locally
# Directory structure is
# ~/Workspaces
#  + Cpp
#    + hidapi (https://github.com/libusb/hidapi)
#  + Docker
#    + dockcross (https://github.com/dockcross/dockcross)
#  + Java
#    + Personal
#      + hid4java (https://github.com/gary-rowe/hid4java)
#
# Dependencies:
# - git
# - Docker Desktop
# - XCode v12.5.1 or higher for darwin-x86-64-aarch64 cross compiler support
#
# Place a symlink to this script in the root of ~/Workspaces
#   cd ~/Workspaces
#   ln -s Java/Personal/hid4java/build-hidapi.sh ./build-hidapi.sh
#
# Supported command line arguments are:
#
# all - build all variants
# windows - build all Windows variants
# linux - build all Linux variants
# darwin - build all macOS variants (not recommended)
# darwin-x86-64 - OS X 64-bit
# darwin-aarch64 - OS X ARM64
# linux-aarch64 - Linux ARMv8 64-bit
# linux-amd64 - Linux AMD 64-bit
# linux-arm - Linux ARMv6 hard float 32-bit (RPi)
# linux-armel - Linux ARMv5 soft float 32-bit
# linux-x86-64 - Linux x86 64-bit (same as AMD64)
# linux-x86 - Linux x86 32-bit
# win32-x86 - Windows 32-bit
# win32-x86-64 - Windows 64-bit
# win32-aarch64 - Windows 64-bit ARM64
#

# Set environment
hid4javaDir="${HOME}/Workspaces/Java/Personal/hid4java"
hidapiDir="${HOME}/Workspaces/Cpp/hidapi"
dockcrossDir="${HOME}/Workspaces/Docker/dockcross"

hardwareName=$(uname -m)
if [[ "${hardwareName}" == "arm64" ]]
  then
    platform="--platform linux/amd64"
  else
    platform=""
fi

# Console colours
red="\033[31m"
yellow="\033[33m"
green="\033[32m"
plain="\033[0m"

# @Tresf: Function to do "make clean" without incurring issues during build
function git-clean {
  echo -e "${yellow}Cleaning hidapi${plain}"
  # Remove all untracked files (including project files)
  git clean -fdx > /dev/null 2>&1 || exit
  # Reset all tracked files
  git reset --hard > /dev/null 2>&1 || exit
}

# Function to provide library file details
function report {

if [[ ! -f $1 ]]
  then
    echo -e "${red}File '$1' was not found.${plain}"
  else
    ls -la $1
    file -b $1
    echo -e "${green}---${plain}"
fi
}

echo -e "${green}------------------------------------------------------------------------${plain}"
echo -e "${yellow}Using '$1' to perform build${plain}"

echo -e "${green}------------------------------------------------------------------------${plain}"

if [[ "$1" == "update" ]]
  then
    echo -e "${green}Updating Dockcross${plain}"
    cd ${dockcrossDir} || exit
    git checkout master
    git pull

    # Windows cross compilers

    # 64-bit (Intel)
    echo -e "${green}Configuring Windows 64-bit${plain}"
    docker run ${platform} --rm dockcross/windows-shared-x64 > ./dockcross-windows-shared-x64
    chmod +x ./dockcross-windows-shared-x64
    mv ./dockcross-windows-shared-x64 /usr/local/bin

    # 32-bit (Intel)
    echo -e "${green}Configuring Windows 32-bit${plain}"
    docker run ${platform} --rm dockcross/windows-shared-x86 > ./dockcross-windows-shared-x86
    chmod +x ./dockcross-windows-shared-x86
    mv ./dockcross-windows-shared-x86 /usr/local/bin

    # 64-bit (ARM64)
    echo -e "${green}Configuring Windows 64-bit ARM64 (aarch64)${plain}"
    docker run ${platform} --rm dockcross/windows-arm64 > ./dockcross-windows-arm64
    chmod +x ./dockcross-windows-arm64
    mv ./dockcross-windows-arm64 /usr/local/bin

    echo -e "${green}Configuring Linux environments${plain}"

    # Linux cross compilers

    # 64 bit (Intel)
    echo -e "${green}Configuring Linux 64-bit${plain}"
    docker run ${platform} --rm dockcross/linux-x64 > ./dockcross-linux-x64
    chmod +x ./dockcross-linux-x64
    mv ./dockcross-linux-x64 /usr/local/bin

    # 32 bit (Intel)
    echo -e "${green}Configuring Linux 32-bit${plain}"
    docker run ${platform} --rm dockcross/linux-x86 > ./dockcross-linux-x86
    chmod +x ./dockcross-linux-x86
    mv ./dockcross-linux-x86 /usr/local/bin

    # ARM cross compilers

    # @Tresf
    # 32-bit ARMv5TE EABI "armel"
    echo -e "${green}Configuring ARMv5TE EABI 32-bit${plain}"
    docker run ${platform} --rm dockcross/linux-armv5 > ./dockcross-linux-armv5
    chmod +x ./dockcross-linux-armv5
    mv ./dockcross-linux-armv5 /usr/local/bin

    # 32-bit ARMv6 EABI
    echo -e "${green}Configuring ARMv6 EABI 32-bit${plain}"
    docker run ${platform} --rm dockcross/linux-armv6 > ./dockcross-linux-armv6
    chmod +x ./dockcross-linux-armv6
    mv ./dockcross-linux-armv6 /usr/local/bin

    # 32-bit ARMv7 hard float
    echo -e "${green}Configuring ARMv7 32-bit${plain}"
    docker run ${platform} --rm dockcross/linux-armv7 > ./dockcross-linux-armv7
    chmod +x ./dockcross-linux-armv7
    mv ./dockcross-linux-armv7 /usr/local/bin

    # 64-bit (arm64, aarch64)
    echo -e "${green}Configuring ARM 64-bit${plain}"
    docker run ${platform} --rm dockcross/linux-arm64 > ./dockcross-linux-arm64
    chmod +x ./dockcross-linux-arm64
    mv ./dockcross-linux-arm64 /usr/local/bin

    # HIDAPI latest release
    echo -e "${green}Updating HIDAPI${plain}"
    cd ${hidapiDir} || exit
    git checkout master
    git pull
  else
    echo -e "${yellow}Skipping updates${plain}"
fi
echo -e "${green}------------------------------------------------------------------------${plain}"

# Build in hidapi project directory
cd ${hidapiDir} || exit

# Windows environments

# 64-bit x86-64
if [[ "$1" == "all" ]] || [[ "$1" == "windows" ]] || [[ "$1" == "win32-x86-64" ]]
  then
    echo -e "${green}Building Windows 64-bit${plain}" && git-clean
    if ! dockcross-windows-shared-x64 bash -c 'sudo apt-get update && sudo apt-get --yes install libudev-dev libusb-1.0-0-dev && sudo ./bootstrap && sudo ./configure --host=x86_64-w64-mingw32 && sudo make';
      then
        echo -e "${red}Failed${plain} - Removing damaged targets"
        rm ${hid4javaDir}/src/main/resources/win32-x86-64/hidapi.dll
        exit
      else
        echo -e "${green}OK${plain}"
        mkdir -p ${hid4javaDir}/src/main/resources/win32-x86-64
        cp windows/.libs/libhidapi-0.dll ${hid4javaDir}/src/main/resources/win32-x86-64/hidapi.dll
    fi
  else
    echo -e "${yellow}Skipping win32-x86-64${plain}"
fi
echo -e "${green}------------------------------------------------------------------------${plain}"

# 64-bit ARM win32-aarch64
if [[ "$1" == "all" ]] || [[ "$1" == "windows" ]] || [[ "$1" == "win32-aarch64" ]]
  then
    echo -e "${green}Building Windows 64-bit ARM64 (aarch64)${plain}" && git-clean
    if ! dockcross-windows-arm64 bash -c 'sudo apt-get update && sudo apt-get --yes install libudev-dev libusb-1.0-0-dev && sudo ./bootstrap && sudo ./configure --host=aarch64-w64-mingw32 && sudo make';
      then
        echo -e "${red}Failed${plain} - Removing damaged targets"
        rm ${hid4javaDir}/src/main/resources/win32-aarch64/hidapi.dll
        exit
      else
        echo -e "${green}OK${plain}"
        mkdir -p ${hid4javaDir}/src/main/resources/win32-aarch64
        cp windows/.libs/libhidapi-0.dll ${hid4javaDir}/src/main/resources/win32-aarch64/hidapi.dll
    fi
  else
    echo -e "${yellow}Skipping win32-aarch64${plain}"
fi
echo -e "${green}------------------------------------------------------------------------${plain}"

# 32-bit x86
if [[ "$1" == "all" ]] || [[ "$1" == "windows" ]] || [[ "$1" == "win32-x86" ]]
  then
    echo -e "${green}Building Windows 32-bit${plain}" && git-clean
    if ! dockcross-windows-shared-x86 bash -c 'sudo ./bootstrap && sudo ./configure --host=i686-w64-mingw32 && sudo make';
      then
        echo -e "${red}Failed${plain} - Removing damaged targets"
        rm ${hid4javaDir}/src/main/resources/win32-x86/hidapi.dll
      else
        echo -e "${green}OK${plain}"
        mkdir -p ${hid4javaDir}/src/main/resources/win32-x86
        cp windows/.libs/libhidapi-0.dll ${hid4javaDir}/src/main/resources/win32-x86/hidapi.dll
    fi
  else
    echo -e "${yellow}Skipping win32-x86${plain}"
fi
echo -e "${green}------------------------------------------------------------------------${plain}"

# Linux environments

# 64-bit (x86-64/amd64)
if [[ "$1" == "all" ]] || [[ "$1" == "linux" ]] || [[ "$1" == "linux-x86-64" ]]
  then
    echo -e "${green}Building Linux 64-bit${plain}" && git-clean
    # Note the use of a double sudo apt-get update here
    if ! dockcross-linux-x64 bash -c 'sudo apt-get update || sudo apt-get update && sudo apt-get --yes install libudev-dev libusb-1.0-0-dev && sudo ./bootstrap && sudo ./configure && sudo make';
      then
        echo -e "${red}Failed${plain} - Removing damaged targets"
        rm ${hid4javaDir}/src/main/resources/linux-x86-64/libhidapi.so
        rm ${hid4javaDir}/src/main/resources/linux-amd64/libhidapi.so
        rm ${hid4javaDir}/src/main/resources/linux-x86-64/libhidapi-libusb.so
        rm ${hid4javaDir}/src/main/resources/linux-amd64/libhidapi-libusb.so
      else
        echo -e "${green}OK${plain}"
        mkdir -p ${hid4javaDir}/src/main/resources/linux-x86-64
        cp linux/.libs/libhidapi-hidraw.so ${hid4javaDir}/src/main/resources/linux-x86-64/libhidapi.so
        cp linux/.libs/libhidapi-hidraw.so ${hid4javaDir}/src/main/resources/linux-amd64/libhidapi.so
        cp libusb/.libs/libhidapi-libusb.so ${hid4javaDir}/src/main/resources/linux-x86-64/libhidapi-libusb.so
        cp libusb/.libs/libhidapi-libusb.so ${hid4javaDir}/src/main/resources/linux-amd64/libhidapi-libusb.so
    fi
  else
    echo -e "${yellow}Skipping linux-x86-64${plain}"
fi
echo -e "${green}------------------------------------------------------------------------${plain}"

# 32-bit
if [[ "$1" == "all" ]] || [[ "$1" == "linux" ]] || [[ "$1" == "linux-x86" ]]
  then
    echo -e "${green}Building Linux 32-bit${plain}" && git-clean
    if ! dockcross-linux-x86 bash -c 'sudo dpkg --add-architecture i386 && sudo apt-get update && sudo apt-get --yes install libudev-dev libusb-1.0-0-dev libudev-dev:i386 libusb-1.0-0-dev:i386 && sudo ./bootstrap && sudo ./configure && sudo make';
      then
        echo -e "${red}Failed${plain} - Removing damaged targets"
        rm ${hid4javaDir}/src/main/resources/linux-x86/libhidapi.so
        rm ${hid4javaDir}/src/main/resources/linux-x86/libhidapi-libusb.so
      else
        echo -e "${green}OK${plain}"
        mkdir -p ${hid4javaDir}/src/main/resources/linux-x86
        cp linux/.libs/libhidapi-hidraw.so ${hid4javaDir}/src/main/resources/linux-x86/libhidapi.so
        cp libusb/.libs/libhidapi-libusb.so ${hid4javaDir}/src/main/resources/linux-x86/libhidapi-libusb.so
    fi
  else
    echo -e "${yellow}Skipping linux-x86${plain}"
fi
echo -e "${green}------------------------------------------------------------------------${plain}"

# ARM environments

# 64-bit (arm64/aarch64)
if [[ "$1" == "all" ]] || [[ "$1" == "linux" ]] || [[ "$1" == "linux-aarch64" ]]
  then
    echo -e "${green}Building ARM64/aarch64 ARMv8${plain}" && git-clean
    if ! dockcross-linux-arm64 bash -c 'sudo dpkg --add-architecture arm64 && sudo apt-get update && sudo apt-get --yes install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu libudev-dev:arm64 libusb-1.0-0-dev:arm64 && sudo ./bootstrap && sudo ./configure --host=aarch64-linux-gnu CC=aarch64-linux-gnu-gcc && sudo make';
      then
        echo -e "${red}Failed${plain} - Removing damaged targets"
        rm ${hid4javaDir}/src/main/resources/linux-aarch64/libhidapi.so
        rm ${hid4javaDir}/src/main/resources/linux-aarch64/libhidapi-libusb.so
      else
        echo -e "${green}OK${plain}"
        mkdir -p ${hid4javaDir}/src/main/resources/linux-aarch64
        cp linux/.libs/libhidapi-hidraw.so ${hid4javaDir}/src/main/resources/linux-aarch64/libhidapi.so
        cp libusb/.libs/libhidapi-libusb.so ${hid4javaDir}/src/main/resources/linux-aarch64/libhidapi-libusb.so
    fi
  else
    echo -e "${yellow}Skipping linux-aarch64${plain}"
fi
echo -e "${green}------------------------------------------------------------------------${plain}"

# 32-bit ARMv6 hard float (linux-arm)
if [[ "$1" == "all" ]] || [[ "$1" == "linux" ]] || [[ "$1" == "linux-arm" ]]
  then
    echo -e "${yellow}Skipping linux-arm (use RPi direct instead)${plain}"
    # It's much easier to just use the original hardware
  else
    echo -e "${yellow}Skipping linux-arm${plain}"
fi
echo -e "${green}------------------------------------------------------------------------${plain}"

# @Tresf
# 32-bit ARM soft float (linux-armel)
if [[ "$1" == "all" ]] || [[ "$1" == "linux" ]] || [[ "$1" == "linux-armel" ]]
  then
    echo -e "${green}Building ARM soft float${plain}"  && git-clean
    make clean &> /dev/null

    # Disabling building hidtest
    sed -i'' -e 's/SUBDIRS \+= hidtest//g' Makefile.am

    arch="armel"
    deps="echo \"Obtaining $arch dependencies...\""
    deps="$deps && sudo dpkg --add-architecture $arch"
    deps="$deps && sudo apt-get update"
    deps="$deps && sudo apt-get --yes install libudev-dev:$arch libusb-1.0-0-dev:$arch"
    deps="$deps ;  echo 'WARNING: Ignoring any errors from previous command'"
    deps="$deps && cp /usr/include/libudev.h ./libudev.h"
    deps="$deps && export PKG_CONFIG_PATH=/usr/lib/arm-linux-gnueabi/pkgconfig/"
    if ! dockcross-linux-armv5 bash -c "$deps && sudo ./bootstrap && sudo ./configure --host=aarch64-unknown-linux-gnueabi && sudo make";
      then
        echo -e "${red}Failed${plain} - Removing damaged targets"
        rm ${hid4javaDir}/src/main/resources/linux-armel/libhidapi.so
        rm ${hid4javaDir}/src/main/resources/linux-armel/libhidapi-libusb.so
      else
        echo -e "${green}OK${plain}"
        mkdir -p ${hid4javaDir}/src/main/resources/linux-armel
        cp linux/.libs/libhidapi-hidraw.so ${hid4javaDir}/src/main/resources/linux-armel/libhidapi.so
        cp libusb/.libs/libhidapi-libusb.so ${hid4javaDir}/src/main/resources/linux-armel/libhidapi-libusb.so
    fi
  else
    echo -e "${yellow}Skipping linux-armel${plain}"
fi
echo -e "${green}------------------------------------------------------------------------${plain}"

# macOS environments (require local build)

if [[ "${hardwareName}" == "arm64" ]]
  then
    # Darwin ARM64 (local)
    if [[ "$1" == "all" ]] || [[ "$1" == "darwin" ]] || [[ "$1" == "darwin-aarch64" ]]
      then
        echo -e "${green}Building OS X Darwin ARM64 (aarch64)${plain}" && git-clean
        ./bootstrap
        ./configure
        if ! make;
          then
            echo -e "${red}Failed${plain} - Removing damaged targets"
            rm ${hid4javaDir}/src/main/resources/darwin-aarch64/libhidapi.dylib
          else
            echo -e "${green}OK${plain}"
            mkdir -p ${hid4javaDir}/src/main/resources/darwin-aarch64
            cp mac/.libs/libhidapi.0.dylib ${hid4javaDir}/src/main/resources/darwin-aarch64/libhidapi.dylib
        fi
      else
        echo -e "${yellow}Skipping darwin-aarch64${plain}"
    fi
  else
    # Darwin Intel (local)
    if [[ "$1" == "all" ]] || [[ "$1" == "darwin" ]] || [[ "$1" == "darwin-x86-64" ]]
      then
        echo -e "${green}Building OS X Darwin Intel (x86-64)${plain}" && git-clean
        make clean
        ./bootstrap
        ./configure
        if ! make;
          then
            echo -e "${red}Failed${plain} - Removing damaged targets"
            rm ${hid4javaDir}/src/main/resources/darwin-x86-64/libhidapi.dylib
          else
            echo -e "${green}OK${plain}"
            mkdir -p ${hid4javaDir}/src/main/resources/darwin-x86-64
            cp mac/.libs/libhidapi.0.dylib ${hid4javaDir}/src/main/resources/darwin-x86-64/libhidapi.dylib
        fi
      else
        echo -e "${yellow}Skipping darwin-x86-64${plain}"
    fi
fi

echo -e "${green}------------------------------------------------------------------------${plain}"

# Report in hid4java project directory
cd ${hid4javaDir} || exit

# List all file info
if [[ "$1" == "update" ]]
  then
    echo -e "${yellow}Skipping file report${plain}"
  else
    echo -e "${green}Reporting on current hidapi libraries in hid4java:${plain}"

    # Windows environments
    echo -e "${green}Windows${plain}"

    echo -e "${green}win32-x86-64${plain}"
    report "src/main/resources/win32-x86-64/hidapi.dll"

    echo -e "${green}win32-x86${plain}"
    report "src/main/resources/win32-x86/hidapi.dll"

    echo -e "${green}win32-aarch64${plain}"
    report "src/main/resources/win32-aarch64/hidapi.dll"

    echo -e "${green}------------------------------------------------------------------------${plain}"

    # Linux environments
    echo -e "${green}Linux${plain}"

    echo -e "${green}linux-x86-64${plain}"
    report "src/main/resources/linux-x86-64/libhidapi.so"
    report "src/main/resources/linux-x86-64/libhidapi-libusb.so"

    echo -e "${green}linux-amd64${plain}"
    report "src/main/resources/linux-amd64/libhidapi.so"
    report "src/main/resources/linux-amd64/libhidapi-libusb.so"

    echo -e "${green}linux-x86${plain}"
    report "src/main/resources/linux-x86/libhidapi.so"
    report "src/main/resources/linux-x86/libhidapi-libusb.so"

    echo -e "${green}------------------------------------------------------------------------${plain}"

    # ARM
    echo -e "${green}ARM${plain}"

    echo -e "${green}linux-arm${plain}"
    report "src/main/resources/linux-arm/libhidapi.so"
    report "src/main/resources/linux-arm/libhidapi-libusb.so"

    echo -e "${green}linux-armel${plain}"
    report "src/main/resources/linux-armel/libhidapi.so"
    report "src/main/resources/linux-armel/libhidapi-libusb.so"

    echo -e "${green}linux-aarch64${plain}"
    report "src/main/resources/linux-aarch64/libhidapi.so"
    report "src/main/resources/linux-aarch64/libhidapi-libusb.so"

    echo -e "${green}------------------------------------------------------------------------${plain}"

    # OS X
    echo -e "${green}OS X${plain}"

    echo -e "${green}darwin${plain}"
    report "src/main/resources/darwin-x86-64/libhidapi.dylib"

    echo -e "${green}darwin-aarch64${plain}"
    report "src/main/resources/darwin-aarch64/libhidapi.dylib"

    echo -e "${green}------------------------------------------------------------------------${plain}"

    echo -e "${green}Done - Check all OK in summary above.${plain}"
fi
echo -e "${green}------------------------------------------------------------------------${plain}"
