#!/usr/bin/env bash

# File: a1111-setup.sh
#
# Usage: a1111-setup.sh
#
# Description: Simple and easy Stable Diffusion WebUI (Automatic1111) and Forge install script for Mac
#
# Options: ---
# Requirements: MacOS
# Bugs: ---
# Notes: ---
# Author: Aleksandar Milanovic (viking1304)
# Version: 0.2.0
# Created: 2023/12/12 19:30:51
# Last modified: 2024/04/05 21:48:08

# Copyright (c) 2023 Aleksandar Milanovic
# https://github.com/viking1304/

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

readonly VERSION='0.2.0'
readonly YEAR='2024'

# available colors for console output
# shellcheck disable=SC2034
readonly green='\033[32m'
# shellcheck disable=SC2034
readonly red='\033[31m'
# shellcheck disable=SC2034
readonly yellow='\033[33m'
# shellcheck disable=SC2034
readonly blue='\033[34m'
# shellcheck disable=SC2034
readonly magenta='\033[35m'
# shellcheck disable=SC2034
readonly cyan='\033[36m'
# shellcheck disable=SC2034
readonly nc='\033[0m' # no color
# default colors
color='blue'
warn_color='yellow'
err_color='red'

# basic message without a new line
msg_nb() {
  local text="$1"
  local color_name='nc'

  if [[ -n "$2" ]]; then
    color_name="$2"
  fi

  # get color code from name
  local color="${!color_name}"

  # shellcheck disable=SC2059
  printf "${color}${text}${nc}"
}

# basic message
msg() {
  msg_nb "$1\n" "$2"
}

# display blank line
msg_br() {
  msg ""
}

# colored message
msg_c() {
  msg "$1" "${color}"
}

# colored message without a new line
msg_c_nb() {
  msg_nb "$1" "${color}"
}

# only the first part of message is colored
msg_cn() {
  msg_c_nb "$1"; msg "$2"
}

# only the first part of message without a new line is colored
msg_cn_nb() {
  msg_c_nb "$1"; msg_nb "$2"
}

# only the second part of message is colored
msg_nc() {
  msg_nb "$1"; msg_c "$2"
}

# only the second part of message without a new line is colored
msg_nc_nb() {
  msg_nb "$1"; msg_c_nb "$2"
}

# warning message
warn_msg() {
  local warn_subject="$1"
  local warn_msg="$2"

  if [[ -z "$2" ]]; then
    warn_subject="WARNING: "
    warn_msg="$1"
  fi

  msg_nb "${warn_subject}" "${warn_color}"; msg "${warn_msg}"
}

# error message
err_msg() {
  local err_subject="$1"
  local err_msg="$2"

  if [[ -z "$2" ]]; then
    err_subject="ERROR: "
    err_msg="$1"
  fi

  msg_nb "${err_subject}" "${err_color}"; msg "${err_msg}"
}

# debug message
dbg_msg() {
  msg_cn "$1: " "$2"
}

main() {
  msg "v$VERSION"
}

main "$@"