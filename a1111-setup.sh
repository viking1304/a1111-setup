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
# Last modified: 2024/07/09 22:07:52

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
declare show_info
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

# only fix errors
fix="errors"

# use recommended PyTorch version
torch_version="automatic"

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

# dry run message
dry_msg() {
  msg_cn "TEST RUN " "$1"
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
    display_help_item "-r" "dry run, only show what would be done"
    display_help_item "-b" "update Homebrew"
    display_help_item "-t" "use development version of PyTorch"
    display_help_item "-f all|none" "apply all fixes or none"
    display_help_item "-d folder_name" "specify the destination folder for webui installation"
    display_help_item "-o forge" "install Forge"
    display_help_item "-c red|green|yellow|blue|magenta|cyan|no-color" "use specified color for messages"
    msg_br
  }

  # parse command line arguments using getopts
  while getopts ':hbtrif:d:o:c:' opt; do
    case $opt in
      h)
        # just set the flag, because the user might want to use a custom color
        help=true
        ;;
      b)
        update_brew=true
        ;;
      t)
        torch_version="develop"
        ;;
      r)
        dry_run=true
        ;;
      i)
        show_info=true
        ;;
      f)
        if [[ "${OPTARG}" != "all" && "${OPTARG}" != "none" ]]; then
          err_msg "Valid arguments for the parameter ${ec}-f${nc} are all and none"
          exit 1
        fi
        fix="${OPTARG}"
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
        if [[ "${OPTARG}" != "forge" ]]; then
          err_msg "Valid argument for the parameter ${ec}-o${nc} is forge"
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
  if [[ "${help}" == true ]]; then
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
  if [[ "${fork}" == "a1111" ]]; then
    repo="${a1111_repo}"
    branch="master"
  else
    repo="${forge_repo}"
    branch="main"
  fi

  # if destination folder is not set use the default location based on fork
  if [[ -z "${dest_dir}" ]]; then
    if [[ "${fork}" == "a1111" ]]; then
      dest_dir="${a1111_dest_dir}"
    else
      dest_dir="${forge_dest_dir}"
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
      dry_msg "echo | /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    fi
    if cpu="arm"; then
      # temporary add Homebrew to PATH if needed
      if ! command -v brew > /dev/null; then
        if [[ "${dry_run}" != true ]]; then
          eval "$(/opt/homebrew/bin/brew shellenv)"
        else
          dry_msg "eval \"\$(/opt/homebrew/bin/brew shellenv)\""
        fi
      fi
      # permanently add Homebrew to PATH if not set in .zprofile
      # shellcheck disable=SC2016
      if ! grep -q 'eval "$(/opt/homebrew/bin/brew shellenv)"' ~/.zprofile; then
        if [[ "${dry_run}" != true ]]; then
          echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "${HOME}/.zprofile"
        else
          dry_msg 'echo "eval \"\$(/opt/homebrew/bin/brew shellenv)\"" >> "${HOME}/.zprofile"'
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
        dry_msg "brew update && brew upgrade"
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
      dry_msg "brew install \"$1\""
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
        err_msg "failed to clone repository ${repo}"
        exit 1
      else
        # shellcheck disable=SC2164
        cd "${dest_dir}"
      fi
    else
      dry_msg "git clone \"$repo\" \"$dest_dir\""
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
      dry_msg "cd \"${dest_dir}\""
    fi
    # force webui upgrade
    if [[ -d ".git" ]]; then
      if [[ "${dry_run}" != true ]]; then
        git reset --hard origin/"${branch}"
      else
        dry_msg "git reset --hard origin/${branch}"
      fi
    else
      if [[ "${dry_run}" != true ]]; then
        git init
        git remote add origin "$repo"
        git fetch --all
        git reset --hard origin/"${branch}"
        git branch --set-upstream-to=origin/"${branch}" "${branch}"
      else
        dry_msg "git init && git remote add origin \"$repo\" && git fetch --all && git reset --hard origin/${branch} && git branch --set-upstream-to=origin/${branch} ${branch}"
      fi
    fi
    if [[ "${dry_run}" != true ]]; then
      git pull
    else
      dry_msg "git pull"
    fi
    if [[ "${dry_run}" != true ]]; then
      if [[ "$(git status | grep modified)" != "" ]]; then
        err_msg "some webui files are still modified"
        show_modified
        exit 1
      fi
    else
      dry_msg "git status | grep modified"
    fi
    # purge pip cache
    if [[ -f "venv/bin/pip" ]]; then
      msg "Purging pip cache..."
      if [[ "${dry_run}" != true ]]; then
        venv/bin/pip cache purge
      else
        dry_msg "venv/bin/pip cache purge"
      fi
    fi
    # remove venv
    if [[ -d "venv" ]]; then
      msg_nc_nb "Trying to remove " "venv"; msg "..."
      if [[ "${dry_run}" != true ]]; then
        rm -rf venv 2> /dev/null
      else
        dry_msg "rm -rf venv"
      fi
      if [[ ! -d "venv" ]]; then
        msg "Successfully removed venv"
      else
        warn "Could not remove venv"
        msg "Trying to remove venv using admin privileges..."
        if [[ "${dry_run}" != true ]]; then
          sudo rm -rf venv 2> /dev/null
        else
          dry_msg "sudo rm -rf venv"
        fi
        if [[ ! -d "venv" ]]; then
          msg "Successfully removed venv using admin privileges"
        else
          err_msg "could not remove venv even using admin privileges"
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
  dbg_hdr "TORCH VERSION"
  dbg_msg "torch" "${torch_version}"
  msg_br
  dbg_hdr "FIXES"
  dbg_msg "fix" "${fix}"
  msg_br
  dbg_hdr "ADDITIONAL INFO"
  dbg_msg "update_brew" "${update_brew}"
  dbg_msg "color" "${color}"
  msg_br
}

# download patch file from URL and patch files
patch_file () {
  local sha256
  sha256=$(curl -s "$1" | shasum -a 256 - | cut -d " " -f1)
  if [[ "${sha256}" == "$2" ]]; then
    if [[ "${dry_run}" != true ]]; then
      # shellcheck disable=SC2154
      if [[ "${debug}" != true ]]; then
        curl -s "$1" | git apply -v -q --index
      else
        curl "$1" | git apply -v --index
      fi
    else
      dry_msg "curl -s \"$1\" | git apply -v -q --index"
    fi
  else
    err_msg "SHA256 mismatch"
    msg_nc "Expected: " "$2"
    msg_nc "Found: " "${sha256}"
    exit 1
  fi
}

# apply patches for A1111
apply_a1111_patches() {
  # use develop version of PyTorch if requested
  if [[ "${torch_version}" == "develop" ]]; then
    if [[ "${cpu}" == "arm" && "${vm}" == false ]]; then
      msg_cn "Applying patch: " "Use development version of torch"
      msg "https://github.com/viking1304/stable-diffusion-webui/commit/36604c3d54fb9377b6070b08f525a011c0373ea6"
      patch_file "https://github.com/AUTOMATIC1111/stable-diffusion-webui/commit/36604c3d54fb9377b6070b08f525a011c0373ea6.patch?full_index=1" "1b9c89c7462ad4f4e3876f56c7217aa5976bf9f19e1c18db85165d8ce20776fe"
    else
      if [[ "${vm}" == false ]]; then
        warn_msg "You cannot use development version of PyTorch, because PyTorch dropped support for Intel Macs"
      else
        warn_msg "You cannot use development version of PyTorch inside virtual machine"
      fi
    fi
    msg_br
  fi

  # check if user specifically requested not to apply any fixes
  if [[ "${fix}" == "none" ]]; then
    return
  fi

  msg_nb "TEMPORARY FIXES" "${warn_color}"; msg " - not needed after release of A1111 v1.10"; msg_br

  # TODO: remove after release of A1111 v1.10
  msg_cn "Applying patch: " "Use different PyTorch versions for ARM and Intel Macs"
  msg "https://github.com/AUTOMATIC1111/stable-diffusion-webui/pull/15851"
  patch_file "https://github.com/AUTOMATIC1111/stable-diffusion-webui/commit/5867be2914c303c2f8ba86ff23dba4b31aeafa79.patch?full_index=1" "c10b445b80875a6b2fd4d83661f206698995a0c3206e391cec1405818d417be0"
  msg_br

  # TODO: remove after release of A1111 v1.10
  msg_cn "Applying patch: " "Update PyTorch for ARM Macs to 2.3.1"
  msg "https://github.com/AUTOMATIC1111/stable-diffusion-webui/pull/16059"
  patch_file "https://github.com/AUTOMATIC1111/stable-diffusion-webui/commit/a772fd9804944cc19c4d6a03ccfbaa6066ce62a8.patch?full_index=1" "24076e71eba70c970c962dd5874c8d491116f5f63da9f576edd82ead98eb51c3"
  msg_br

  # TODO: remove after release of A1111 v1.10
  msg_cn "Applying patch: " "Prioritize python3.10 over python3 if both are available"
  msg "https://github.com/AUTOMATIC1111/stable-diffusion-webui/pull/16092"
  patch_file "https://github.com/AUTOMATIC1111/stable-diffusion-webui/commit/ec3c31e7a19f3240bfba072787399eb02b88dc9e.patch?full_index=1" "8c5ef814f61ecb3036315a8d1cde7d3dce38e7480e3325e54debb1bf4a15fdba"
  msg_br

  msg "FIXES" "${warn_color}"; msg_br

  # set recommended command line args
  if [[ "${vm}" != true ]]; then
    if [[ "${cpu}" == "arm" ]]; then
      msg_cn "Applying patch: " "Set recommended command line args"
      msg_nc "COMMANDLINE_ARGS=" "\"--skip-torch-cuda-test --opt-sub-quad-attention --upcast-sampling --no-half-vae --use-cpu interrogate\""
      patch_file "https://raw.githubusercontent.com/viking1304/a1111-setup/develop/patches/lineargs.patch" "23f4ef196c3e6dc868de6b664c0feca5da08c91db4d9b2829587c62a37433747"
    else
      msg_cn "Applying patch: " "Set recommended command line args for Intel"
      msg_nc "COMMANDLINE_ARGS=" "\"--skip-torch-cuda-test --opt-sub-quad-attention --upcast-sampling --no-half --lowvram --use-cpu interrogate\""
      patch_file "https://raw.githubusercontent.com/viking1304/a1111-setup/86814db94400c4574fbf473378c03ab30423ef0d/patches/intel-lineargs.patch" "62ba57613211b41ae4c505d896f88be590348f759b746bf469a8df4cdaf314aa"
    fi
    msg_br
  fi

  # set command line args for VM
  if [[ "${vm}" == true ]]; then
    msg_cn "Applying patch: " "Set working command line args for VM"
    msg_nc "COMMANDLINE_ARGS=" "\"--skip-torch-cuda-test --opt-sub-quad-attention --upcast-sampling --no-half --lowvram --use-cpu all\""
    patch_file "https://raw.githubusercontent.com/viking1304/a1111-setup/86814db94400c4574fbf473378c03ab30423ef0d/patches/vm-lineargs.patch" "c48fdeedfa8c370b789bcc21bdac73b34b3bd603559d0bead9d30d37f791d0d8"
    msg_br
  fi

  # non-essential patches
  if [[ "${fix}" == "all" ]]; then
    msg_cn "Applying patch: " "Fix cannot convert a MPS Tensor to float64 dtype error"
    msg "https://github.com/AUTOMATIC1111/stable-diffusion-webui/pull/13099"
    patch_file "https://github.com/AUTOMATIC1111/stable-diffusion-webui/commit/ac4bfdb6434054a949384fe2b4b52e36e0be8db0.patch?full_index=1" "cc552f22e189f0446182f2ea67b84d3f496e255d879564c08f32830b008a5e93"
    msg_br
  fi
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
  if [[ "${debug}" == true || "${show_info}" == true ]]; then
    debug_info
  fi

  if [[ "${show_info}" == true ]]; then
    exit 0
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

  # apply patches
  if [[ "${fork}" == "a1111" ]]; then
    apply_a1111_patches
  fi
}

# set debug mode
# debug=true
# ignore_vm=true

main "$@"