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
# Last modified: 2024/07/07 22:16:18

# Copyright (c) 2024 Aleksandar Milanovic
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

# declare variables
declare debug
declare ignore_vm
declare dry_run
vm=false

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

# repositories and default destination folders
readonly a1111_repo="https://github.com/AUTOMATIC1111/stable-diffusion-webui.git"
readonly a1111_dest_dir="${HOME}/stable-diffusion-webui"
readonly forge_repo="https://github.com/lllyasviel/stable-diffusion-webui-forge.git"
readonly forge_dest_dir="${HOME}/stable-diffusion-webui-forge"

# do not update Homebrew unless requested
update_brew=false

# install A1111 by default
fork="a1111"

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
  local warn_message="$2"

  if [[ -z "$2" ]]; then
    warn_subject="WARNING: "
    warn_message="$1"
  fi

  msg_nb "${warn_subject}" "${warn_color}"; msg "${warn_message}"
}

# error message
err_msg() {
  local err_subject="$1"
  local err_message="$2"

  if [[ -z "$2" ]]; then
    err_subject="ERROR: "
    err_message="$1"
  fi

  msg_nb "${err_subject}" "${err_color}"; msg "${err_message}"
}

# debug header
dbg_hdr () {
  msg "$1" "${warn_color}"
}

# debug message
dbg_msg() {
  msg_cn "$1:" " $2"
}

# display welcome message
welcome_message() {
  msg "Welcome to"
  msg_c "     _        _     _            _ _  __  __           _                "
  msg_c " ___| |_ __ _| |__ | | ___    __| (_)/ _|/ _|_   _ ___(_) ___  _ __     "
  msg_c "/ __| __/ _\` | '_ \| |/ _ \  / _\` | | |_| |_| | | / __| |/ _ \| '_ \  "
  msg_c "\__ \ || (_| | |_) | |  __/ | (_| | |  _|  _| |_| \__ \ | (_) | | | |   "
  msg_c "|___/\__\__,_|_.__/|_|\___|  \__,_|_|_| |_|  \__,_|___/_|\___/|_| |_|   "
  msg_br
  msg_nc "                                            I N S T A L L E R  " "v${VERSION}"
  msg_br
  msg_nc_nb "Copyright " "(c) ${YEAR}"; msg_nc_nb " Aleksandar Milanovic (" "viking1304"; msg ")"
  msg_br
  msg_nc "https://" "github.com/viking1304/a111-setup"
  msg_br
}

# check if sudo requires a password and ask user to enter it if necessary
is_password_required () {
  # check if sudo requires a password
  if ! sudo -n true 2>/dev/null; then
    # show custom password prompt
    msg_nc_nb "Please enter password for user " "$USER"; msg_nb ": "
    if [[ "${dry_run}" != true ]]; then
      # ask for user password
      sudo -v -p ""
    else
      msg_br
    fi
    msg_br
  fi
}

# keep-alive by updating existing 'sudo' time stamp until script has finished
keep_alive() {
  while true; do
    sudo -n true  # refresh sudo timestamp without prompt
    sleep 60      # sleep for 60 seconds
    kill -0 "$$" || exit  # check if script is still running; exit if not
  done 2>/dev/null &
}

# parse command line arguments
parase_command_line_arguments() {
  # convert error color to color code
  local ec="${!err_color}"
  # postpone displaying the help until all arguments are parsed
  local help=false

  # display help
  display_help() {
    display_help_header () {
      msg_cn "$0" " usage:"
    }

    display_help_item () {
      local item="$1"
      local description="$2"
      msg_nb "        ["; msg_cn "${item}" "] ${description}"
    }

    display_help_header
    display_help_item "-h" "display help"
    display_help_item "-b" "update Homebrew"
    display_help_item "-d folder_name" "specify the destination folder for webui installation"
    display_help_item "-o a1111|forge" "install A1111 or Forge"
    display_help_item "-c red|green|yellow|blue|magenta|cyan|no-color" "use specified color for messages"
    msg_br
  }

  # parse command line arguments using getopts
  while getopts ':hbd:o:c:' opt; do
    case $opt in
      h)
        # just set the flag, because the user might want to use a custom color
        help=true
        ;;
      b)
        update_brew=true
        ;;
      d)
        # ensure that destination does not start with dot
        if [[ "${OPTARG}" == .* ]]; then
          err_msg "Do not install webui under a directory with leading dot (.)"
          msg_cn "MORE INFO: " "https://github.com/AUTOMATIC1111/stable-diffusion-webui/issues/13292"
          exit 1
        fi
        dest_dir="${OPTARG}"
        ;;
      o)
        if [[ "${OPTARG}" != "forge"  && "${OPTARG}" != "a1111" ]]; then
          err_msg "Valid arguments for the parameter ${ec}-o${nc} are a1111 and forge"
          exit 1
        fi
        fork="${OPTARG}"
        ;;
      c)
        # handle invalid colors
        if [[ "${OPTARG}" != "red" && "${OPTARG}" != "green" && "${OPTARG}" != "yellow" &&
              "${OPTARG}" != "blue" && "${OPTARG}" != "magenta" && "${OPTARG}" != "cyan" &&
              "${OPTARG}" != "no-color"
        ]]; then
          err_msg "Valid arguments for the parameter ${ec}-c${nc} are red, green, yellow, blue, magenta, cyan and no-color"
          exit 1
        fi
        color="${OPTARG}"
        ;;
      \?)
        # handle invalid options
        err_msg "Invalid option ${ec}-${OPTARG}${nc}"
        exit 1
        ;;
      :)
        # handle missing arguments
        err_msg "Option ${ec}-${OPTARG}${nc} requires an argument"
        exit 1
        ;;
    esac
  done

  # finally display help if the flag was set
  if [[ "$help" == "true" ]]; then
    display_help
    exit 0
  fi
}

# detect processor and virtual machine
detect_cpu_and_vm() {
  msg "Detecting processor..."

  if [[ "$(sysctl -n machdep.cpu.brand_string)" =~ ^.*"Intel".*$ ]]; then
    cpu="intel"
    msg_nc "Running on " "Intel"
  else
    cpu="arm"
    msg_nc "Running on " "ARM"
  fi

  if [[ "${ignore_vm}" != true && "$(system_profiler SPHardwareDataType | grep -c "Identifier.*VirtualMac")" -eq 1 ]]; then
    vm=true
    msg_br
    warn_msg "Running inside virtual machine"
  fi

  msg_br
}

# set the repository, branch and destination folder
set_repo_and_dest_dir() {
  if [[ "$fork" == "a1111" ]]; then
    repo="$a1111_repo"
    branch="master"
  else
    repo="$forge_repo"
    branch="main"
  fi

  # if destination folder is not set use the default location based on fork
  if [[ -z "$dest_dir" ]]; then
    if [[ "$fork" == "a1111" ]]; then
      dest_dir="$a1111_dest_dir"
    else
      dest_dir="$forge_dest_dir"
    fi
  fi

  # treat destination folder as subfolder of home directory, unless it starts with slash
  if [[ "${dest_dir:0:1}" != '/' ]]; then
    dest_dir="${HOME}/${dest_dir}"
  fi
  # remove trailing slash
  dest_dir="${dest_dir%/}"
}


# install Homebrew
install_homebrew() {
  msg_nc_nb "Checking for " "Homebrew"; msg "..."
  if [[ -z "$(which brew)" ]]; then
    msg_br
    msg "Installing Homebrew..."
    if [[ "${dry_run}" != true ]]; then
      echo | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
      dbg_msg "dry_run" "echo | /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    fi
    if cpu="arm"; then
      # temporary add Homebrew to PATH if needed
      if ! command -v brew > /dev/null; then
        if [[ "${dry_run}" != true ]]; then
          eval "$(/opt/homebrew/bin/brew shellenv)"
        else
          dbg_msg "dry_run" "eval \"\$(/opt/homebrew/bin/brew shellenv)\""
        fi
      fi
      # permanently add Homebrew to PATH if not set in .zprofile
      # shellcheck disable=SC2016
      if ! grep -q 'eval "$(/opt/homebrew/bin/brew shellenv)"' ~/.zprofile; then
        if [[ "${dry_run}" != true ]]; then
          echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "${HOME}/.zprofile"
        else
          dbg_msg "dry_run" 'echo "eval \"\$(/opt/homebrew/bin/brew shellenv)\"" >> "${HOME}/.zprofile"'
        fi
      fi
    fi
  else
    msg "Homebrew is already installed"
    if [[ "${update_brew}" == true ]]; then
      if [[ "${dry_run}" != true ]]; then
        msg_br
        brew update
        brew upgrade
      else
        msg_br
        dbg_msg "dry_run" "brew update && brew upgrade"
      fi
    fi
  fi
  msg_br
}

# install Homebrew package
brew_install() {
    msg_nc_nb "Installing " "$1"; msg "..."
    if [[ "${dry_run}" != true ]]; then
      if brew list "$1" &>/dev/null; then
          msg "$1 is already installed"
      else
        brew install "$1" && msg "$1 is installed"
      fi
    else
      dbg_msg "dry_run" "brew install \"$1\""
    fi
}

 # install required packages
install_required_packages() {
  brew_install cmake
  brew_install protobuf
  brew_install rust
  brew_install python@3.10
  brew_install git
  brew_install wget
  msg_br
}

# show list of modified files
show_modified() {
  msg "List of modified files:"
  git status | grep modified | sed 's/	modified: //'
}

# install A1111 or Forge
install_webui() {
  # check if destination folder exists
  if [[ ! -d "${dest_dir}" ]]; then
    msg_nc_nb "Installing " "${fork}"; msg_nc_nb " into " "${dest_dir}"; msg "..."
    # clone chosen repository to destination folder
    if [[ "${dry_run}" != true ]]; then
      if ! git clone "$repo" "$dest_dir"; then
        msg_err "failed to clone repository ${repo}"
        exit 1
      else
        # shellcheck disable=SC2164
        cd "${dest_dir}"
      fi
    else
      dbg_msg "dry_run" "git clone \"$repo\" \"$dest_dir\""
    fi
  else
    if [[ "$(ls -A "${dest_dir}")" ]]; then
      msg_nc_nb "Updating " "${fork}"; msg_nc_nb " installation in " "${dest_dir}"; msg "..."
    else
      msg_nc_nb "Installing " "${fork}"; msg_nc_nb " into " "${dest_dir}"; msg "..."
    fi
    if [[ "${dry_run}" != true ]]; then
      # shellcheck disable=SC2164
      cd "${dest_dir}"
    else
      dbg_msg "dry_run" "cd \"${dest_dir}\""
    fi
    # force webui upgrade
    if [[ -d ".git" ]]; then
      if [[ "${dry_run}" != true ]]; then
        git reset --hard origin/"${branch}"
      else
        dbg_msg "dry_run" "git reset --hard origin/${branch}"
      fi
    else
      if [[ "${dry_run}" != true ]]; then
        git init
        git remote add origin "$repo"
        git fetch --all
        git reset --hard origin/"${branch}"
        git branch --set-upstream-to=origin/"${branch}" "${branch}"
      else
        dbg_msg "dry_run" "git init && git remote add origin \"$repo\" && git fetch --all && git reset --hard origin/${branch} && git branch --set-upstream-to=origin/${branch} ${branch}"
      fi
    fi
    if [[ "${dry_run}" != true ]]; then
      git pull
    else
      dbg_msg "dry_run" "git pull"
    fi
    if [[ "${dry_run}" != true ]]; then
      if [[ "$(git status | grep modified)" != "" ]]; then
        err_msg "some webui files are still modified"
        show_modified
        exit 1
      fi
    else
      dbg_msg "dry_run" "git status | grep modified"
    fi
    # purge pip cache
    if [[ -f "venv/bin/pip" ]]; then
      msg "Purging pip cache..."
      if [[ "${dry_run}" != true ]]; then
        venv/bin/pip cache purge
      else
        dbg_msg "dry_run" "venv/bin/pip cache purge"
      fi
    fi
    # remove venv
    if [[ -d "venv" ]]; then
      msg_nc_nb "Trying to remove " "venv"; msg "..."
      if [[ "${dry_run}" != true ]]; then
        rm -rf venv 2> /dev/null
      else
        dbg_msg "dry_run" "rm -rf venv"
      fi
      if [[ ! -d "venv" ]]; then
        msg "Successfully removed venv"
      else
        warn "Could not remove venv"
        msg "Trying to remove venv using admin privileges..."
        if [[ "${dry_run}" != true ]]; then
          sudo rm -rf venv 2> /dev/null
        else
          dbg_msg "dry_run" "sudo rm -rf venv"
        fi
        if [[ ! -d "venv" ]]; then
          msg "Successfully removed venv using admin privileges"
        else
          err "could not remove venv even using admin privileges"
          exit 1
        fi
      fi
    fi
  fi
  msg_br
}
# display debug info
debug_info() {
  dbg_hdr "SCRIPT"
  dbg_msg "script" "${BASH_SOURCE[0]}"
  dbg_msg "version" "${VERSION}"
  dbg_msg "year" "${YEAR}"
  msg_br
  dbg_hdr "CPU AND VM"
  dbg_msg "cpu" "${cpu}"
  dbg_msg "vm" "${vm}"
  msg_br
  dbg_hdr "INSTALLATION"
  dbg_msg "fork" "${fork}"
  dbg_msg "repo" "${repo}"
  dbg_msg "master" "${branch}"
  dbg_msg "destination_dir" "${dest_dir}"
  msg_br
  dbg_hdr "ADDITIONAL INFO"
  dbg_msg "update_brew" "${update_brew}"
  dbg_msg "color" "${color}"
  msg_br
}

main() {
  # display blank line
  msg_br

  # exit script if not run on macOS
  if [[ "$(uname -s)" != "Darwin" ]]; then
    err_msg "This script can only be used on macOS!"
    exit 1
  fi

  # parse command line arguments
  parase_command_line_arguments "$@"

  # show welcome message
  welcome_message

  # detect CPU and VM
  detect_cpu_and_vm

  # set the repository, branch and destination folder
  set_repo_and_dest_dir

  # show debug info
  if [[ "${debug}" == true ]]; then
    debug_info
  fi

  # check if sudo requires a password and ask user to enter it if necessary
  is_password_required

  # keep-alive by updating existing 'sudo' time stamp until script has finished
  keep_alive

  # install Homebrew
  install_homebrew

  # install required packages
  install_required_packages

  # (re)install A1111 or Forge
  install_webui
}

# set debug mode
# debug=true
# dry_run=true
# ignore_vm=true

main "$@"