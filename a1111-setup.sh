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
# Version: 0.2.4
# Created: 2023/12/12 19:30:51
# Last modified: 2024/10/30 19:47:30

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

readonly VERSION='0.2.4'
readonly YEAR='2024'

# declare variables
declare debug
declare ignore_vm
declare dry_run
declare show_info
declare -i ram
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
  else
    msg_nc_nb "Password for user " "$USER"; msg " not required."
  fi
  msg_br
}

# keep-alive by updating existing 'sudo' time stamp until script has finished
keep_sudo_alive() {
  while true; do
    sudo -n true
    sleep 30
  done &
  SUDO_KEEP_ALIVE_PID=$!
  if [[ "${debug}" == true ]]; then
    msg_nc "keep_sudo_alive process started with PID: " "$SUDO_KEEP_ALIVE_PID"
    msg_br
  fi
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
    display_help_item "-i" "show debug info and exit"
    display_help_item "-f all|none" "apply all fixes or none"
    display_help_item "-d folder_name" "specify the destination folder for webui installation"
    display_help_item "-o forge" "install Forge"
    display_help_item "-e recommended|useful" "install recommended extensions only, or include additional useful ones as well"
    display_help_item "-s folder_name" "specify the folder with your backed up settings"
    display_help_item "-c red|green|yellow|blue|magenta|cyan|no-color" "use specified color for messages"
    msg_br
  }

  # parse command line arguments using getopts
  while getopts ':hbtrif:d:o:e:s:c:' opt; do
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
      e)
        if [[ "${OPTARG}" != "recommended" && "${OPTARG}" != "useful" ]]; then
          err_msg "Valid arguments for the parameter ${ec}-e${nc} are recommended and useful"
          exit 1
        fi
        add_extensions="${OPTARG}"
        ;;
      s)
        settings_dir="${OPTARG}"
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

# get basic system info
get_basic_system_info() {
  if [[ "${show_info}" != true ]]; then
    msg "Detecting basic system information..."
  fi

  if [[ "$(sysctl -n machdep.cpu.brand_string)" =~ ^.*"Intel".*$ ]]; then
    cpu="intel"
    if [[ "${show_info}" != true ]]; then
      msg_nc "Running on " "Intel"
    fi
  else
    cpu="arm"
    if [[ "${show_info}" != true ]]; then
      msg_nc "Running on " "ARM"
    fi
  fi

  ram="$(system_profiler SPHardwareDataType | sed -n '/Memory:/s/[^0-9]*//gp')"
  if [[ "${show_info}" != true ]]; then
    msg_nc "Memory: " "${ram} GB"
  fi

  if [[ "${ignore_vm}" != true && "$(system_profiler SPHardwareDataType | grep -c "Identifier.*VirtualMac")" -eq 1 ]]; then
    vm=true
    if [[ "${show_info}" != true ]]; then
      msg_br
      warn_msg "Running inside virtual machine"
    fi
  fi

  if [[ "${show_info}" != true ]]; then
    msg_br
  fi
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
  if [[ -z "${brew_path}" ]]; then
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
        git reset --hard "origin/${branch}"
      else
        dry_msg "git reset --hard \"origin/${branch}\""
      fi
    else
      if [[ "${dry_run}" != true ]]; then
        git init
        git remote add origin "$repo"
        git fetch --all
        git reset --hard "origin/${branch}"
        git branch --set-upstream-to="origin/${branch}" "${branch}"
      else
        dry_msg "git init"
        dry_msg "git remote add origin \"$repo\""
        dry_msg "git fetch --all"
        dry_msg "git reset --hard \"origin/${branch}\""
        dry_msg "git branch --set-upstream-to=\"origin/${branch}\" \"${branch}\""
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

install_extensions() {
  if [[ "${add_extensions}" == "recommended" || "${add_extensions}" == "useful" ]]; then
    dbg_hdr "EXTENSIONS"
    msg_br
    msg_nc_nb "Installing " "recommended"; msg " extensions..."
    # extensions already integrated in forge
    if [[ "${fork}" == "a1111" ]]; then
      if [[ "${dry_run}" != true ]]; then
        git clone https://github.com/Mikubill/sd-webui-controlnet "${ext}/sd-webui-controlnet.git"
        git clone https://github.com/pkuliyi2015/multidiffusion-upscaler-for-automatic1111.git "${ext}/multidiffusion-upscaler-for-automatic1111"
      else
        dry_msg "git clone https://github.com/Mikubill/sd-webui-controlnet.git \"${ext}/sd-webui-controlnet\""
        dry_msg "git clone https://github.com/pkuliyi2015/multidiffusion-upscaler-for-automatic1111.git \"${ext}/multidiffusion-upscaler-for-automatic1111\""
      fi
    fi
    # other recommended extensions
    if [[ "${dry_run}" != true ]]; then
      git clone https://github.com/BlafKing/sd-civitai-browser-plus.git "${ext}/sd-civitai-browser-plus"
      git clone https://github.com/alexandersokol/sd-model-organizer.git "${ext}/sd-model-organizer"
      git clone https://github.com/zanllp/sd-webui-infinite-image-browsing.git "${ext}/sd-webui-infinite-image-browsing"
      git clone https://github.com/hnmr293/sd-webui-cutoff.git "${ext}/sd-webui-cutoff"
    else
      dry_msg "git clone https://github.com/BlafKing/sd-civitai-browser-plus.git \"${ext}/sd-civitai-browser-plus\""
      dry_msg "git clone https://github.com/alexandersokol/sd-model-organizer.git \"${ext}/sd-model-organizer\""
      dry_msg "git clone https://github.com/zanllp/sd-webui-infinite-image-browsing.git \"${ext}/sd-webui-infinite-image-browsing\""
      dry_msg "git clone https://github.com/hnmr293/sd-webui-cutoff.git \"${ext}/sd-webui-cutoff\""
    fi
    msg_br
  fi

  # non-essential extensions
  if [[ "${add_extensions}" == "useful" ]]; then
    msg_nc_nb "Installing " "non-essential"; msg " extensions..."
    # a1111 specific extensions
    if [[ "${fork}" == "a1111" ]]; then
      if [[ "${dry_run}" != true ]]; then
        git clone https://github.com/deforum-art/sd-webui-deforum.git "${ext}/deforum-for-automatic1111-webui"
        git clone https://github.com/continue-revolution/sd-webui-animatediff.git "${ext}/sd-webui-animatediff"
      else
        dry_msg "git clone https://github.com/deforum-art/sd-webui-deforum.git \"${ext}/deforum-for-automatic1111-webui\""
        dry_msg "git clone https://github.com/continue-revolution/sd-webui-animatediff.git \"${ext}/sd-webui-animatediff\""
      fi
    fi
    # forge specific extensions
    if [[ "${fork}" == "forge" ]]; then
      if [[ "${dry_run}" != true ]]; then
        git clone https://github.com/deforum-art/sd-forge-deforum.git "${ext}/sd-forge-deforum"
        git clone https://github.com/continue-revolution/sd-forge-animatediff.git "${ext}/sd-webui-animatediff"
      else
        dry_msg "git clone https://github.com/deforum-art/sd-forge-deforum.git \"${ext}/sd-forge-deforum\""
        dry_msg "git clone https://github.com/continue-revolution/sd-forge-animatediff.git \"${ext}/sd-webui-animatediff\""
      fi
    fi
    # common extensions
    if [[ "${dry_run}" != true ]]; then
      git clone https://github.com/canisminor1990/sd-webui-lobe-theme.git "${ext}/sd-webui-lobe-theme"
      git clone https://github.com/DominikDoom/a1111-sd-webui-tagcomplete.git "${ext}/a1111-sd-webui-tagcomplete"
      git clone https://github.com/adieyal/sd-dynamic-prompts.git "${ext}/sd-dynamic-prompts"
      git clone https://github.com/vladmandic/sd-extension-system-info.git "${ext}/sd-extension-system-info"
      git clone https://github.com/hako-mikan/sd-webui-regional-prompter.git "${ext}/sd-webui-regional-prompter"
    else
      dry_msg "git clone https://github.com/canisminor1990/sd-webui-lobe-theme.git \"${ext}/sd-webui-lobe-theme\""
      dry_msg "git clone https://github.com/DominikDoom/a1111-sd-webui-tagcomplete.git \"${ext}/a1111-sd-webui-tagcomplete\""
      dry_msg "git clone https://github.com/adieyal/sd-dynamic-prompts.git \"${ext}/sd-dynamic-prompts\""
      dry_msg "git clone https://github.com/vladmandic/sd-extension-system-info.git \"${ext}/sd-extension-system-info\""
      dry_msg "git clone https://github.com/hako-mikan/sd-webui-regional-prompter.git \"${ext}/sd-webui-regional-prompter\""
    fi
    msg_br
  fi
}

# restore settings
restore_settings() {
  # do not try to restore anything if settings_dir is not set
  if [[ -z "${settings_dir}" ]]; then
    return
  fi
  # treat settings folder as subfolder of script directory, unless it starts with slash
  if [[ "${settings_dir:0:1}" != '/' ]]; then
    settings_dir="${script_dir}/${settings_dir}"
  fi
  # remove trailing slash
  settings_dir="${settings_dir%/}"

  if [[ -d "${settings_dir}" ]]; then
    dbg_hdr "SETTINGS"
    msg_br
    msg_nc_nb "Restoring settings from " "${settings_dir}"; msg "..."
    # restore config.json if it exists
    if [[ -f "${settings_dir}/config.json" ]]; then
      if [[ "${dry_run}" != true ]]; then
        cp "${settings_dir}/config.json" "${dest_dir}/"
      else
        dry_msg "cp \"${settings_dir}/config.json\" \"${dest_dir}/\""
      fi
    fi
    # restore lobe_theme_config.json if it exists
    # if forge-specific lobe_theme_config.json exists it should be used for forge
    if [[ "${fork}" == "forge" && -f "${settings_dir}/lobe-theme/lobe_theme_config_forge.json" ]]; then
      if [[ "${dry_run}" != true ]]; then
        if [[ -d "${ext}/sd-webui-lobe-theme" ]]; then
          cp "${settings_dir}/lobe-theme/lobe_theme_config_forge.json" "${ext}/sd-webui-lobe-theme/lobe_theme_config.json"
        fi
      else
        dry_msg "cp \"${settings_dir}/lobe-theme/lobe_theme_config_forge.json\" \"${ext}/sd-webui-lobe-theme/lobe_theme_config.json\""
      fi
    else
      # if forge-specific lobe_theme_config.json doesn't exist, the default one will be used for both forks
      # otherwise the default lobe_theme_config.json will be used for A1111 only
      if [[ -f "${settings_dir}/lobe-theme/lobe_theme_config.json" ]]; then
        if [[ "${dry_run}" != true ]]; then
          if [[ -d "${ext}/sd-webui-lobe-theme" ]]; then
            cp "${settings_dir}/lobe-theme/lobe_theme_config.json" "${ext}/sd-webui-lobe-theme/lobe_theme_config.json"
          fi
        else
          dry_msg "cp \"${settings_dir}/lobe-theme/lobe_theme_config.json\" \"${ext}/sd-webui-lobe-theme/lobe_theme_config.json\""
        fi
      fi
    fi
    # restore model-organizer database if it exists
    if [[ -f "${settings_dir}/model-organizer/database.sqlite" ]]; then
      if [[ "${dry_run}" != true ]]; then
        if [[ -d "${ext}/sd-model-organizer" ]]; then
          cp "${settings_dir}/model-organizer/database.sqlite" "${ext}/sd-model-organizer"
        fi
      else
        dry_msg "cp \"${settings_dir}/model-organizer/database.sqlite\" \"${ext}/sd-model-organizer\""
      fi
    fi
    # restore wildcards if folder exists
    if  [[ -d "${settings_dir}/wildcards" ]]; then
      if [[ "${dry_run}" != true ]]; then
        if [[ -d "${ext}/sd-dynamic-prompts" ]]; then
          cp -r "${settings_dir}/wildcards" "${ext}/sd-dynamic-prompts"
        fi
      else
        dry_msg "cp -r \"${settings_dir}/wildcards\" \"${ext}/sd-dynamic-prompts\""
      fi
    fi
    msg_br
  else
    warn_msg "Settings folder ${!color}${settings_dir}${nc} not fund!"
    msg_br
  fi
}

# show system info
show_sys_info () {
  get_sys_info() {
    local command="$1"
    local result
    if [[ "$command" == "sw_vers" ]]; then
      result=$(sw_vers | sed -e "s/^/\\${!color}/; s/:/\\${nc}: /g; s/\t//g")
    else
      result=$(system_profiler "$command" | sed -n '5,10 {
          s/^ *//
          s/:/:'\\"${nc}"'/g
          s/^/'\\"${!color}"'/ 
          p
      }')
    fi
    msg "$result"
  }
  dbg_hdr "SYSTEM INFORMATION"
  get_sys_info "SPHardwareDataType"
  msg_br
  dbg_hdr "GRAPHICS INFORMATION"
  get_sys_info "SPDisplaysDataType"
  msg_br
  dbg_hdr "OS VERSION"
  get_sys_info "sw_vers"
}

# show python version
show_python_versions() {
  dbg_hdr "PYTHON VERSIONS"
  for v in {10..13}; do
    if command -v python3."${v}" &> /dev/null; then
      python_version="$(python3."${v}" --version)"
      python_path="$(which python3."${v}")"
      msg_cn "${python_version#*[[:space:]]}:" " ${python_path}"
    fi
  done
  if command -v python3 &> /dev/null; then
    p3="$(python3 --version)";
    msg_cn "Default:" " ${p3#*[[:space:]]}"
  fi
}

# get brew info
get_brew_info() {
  brew_path="$(which brew)"
  if [[ -z "$brew_path" ]]; then
    brew_info="NOT INSTALLED"
  else
    if [[ "$brew_path" == /opt/homebrew/* ]]; then
      brew_info="ARM"
    else
      brew_info="Intel"
    fi
  fi
}

# display brew info
show_brew_info() {
  dbg_hdr "HOMEBREW INFORMATION"
  msg_cn "Homebrew:" " ${brew_info}"
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
  local curl_opts=""
  local git_opts="-v --index"
  sha256=$(curl -s "$1" | shasum -a 256 - | cut -d " " -f1)
  if [[ "${sha256}" == "$2" ]]; then
    if [[ "${dry_run}" != true ]]; then
      if [[ "${debug}" != true ]]; then
        curl_opts="-s"
        git_opts="-q --index"
      fi
      if curl $curl_opts "$1" | git apply $git_opts; then
        msg "Successfully applied patch"
      else
        err_msg "Could not apply patch"
        exit 1
      fi
    else
      dry_msg "curl \"$1\" | git apply $git_opts"
    fi
  else
    err_msg "SHA256 mismatch"
    msg_nc "Expected: " "$2"
    msg_nc "Found: " "${sha256}"
    exit 1
  fi
}

# apply patches
apply_patches() {
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

  msg_nb "TEMPORARY PATCHES" "${warn_color}"; msg " - not needed after the release of A1111 v1.11"; msg_br

  if [[ "${fork}" == "a1111" ]]; then
    msg_cn "Applying patch: " "Update stable diffusion 1.5 URL"
    msg "https://github.com/AUTOMATIC1111/stable-diffusion-webui/pull/16460"
    patch_file "https://github.com/AUTOMATIC1111/stable-diffusion-webui/commit/f57ec2b53b2fd89672f5611dee3c5cb33738c30a.patch?full_index=1" "29d495dbf3cca6e69f6a535a0708f480d35f6886dd4adce3a9ef0426221f5da6"
    patch_file "https://github.com/AUTOMATIC1111/stable-diffusion-webui/commit/c9a06d1093df828c7ff1dd356f38cf5ae41c1227.patch?full_index=1" "062fd309cb851ad69f2fb9131d46c3e79975b1795b5f922892ddf412951fee09"
  fi
  msg_br

  dbg_hdr "FIXES"
  msg_br

  # set recommended command line args
  if [[ "${vm}" != true ]]; then
    if [[ "${cpu}" == "arm" ]]; then
      msg_cn_nb "Applying patch: " "Set recommended command line args"
      if (( "${ram}" >= 16 )); then
        msg " for Macs with 16 GB or more of RAM"
        if [[ "${fork}" == "a1111" ]]; then
          msg "COMMANDLINE_ARGS=\"--skip-torch-cuda-test --opt-sub-quad-attention --upcast-sampling --no-half-vae --use-cpu interrogate\""
          patch_file "https://raw.githubusercontent.com/viking1304/a1111-setup/main/patches/lineargs-arm.patch" "23f4ef196c3e6dc868de6b664c0feca5da08c91db4d9b2829587c62a37433747"
        fi
        if [[ "${fork}" == "forge" ]]; then
          msg "COMMANDLINE_ARGS=\"--skip-torch-cuda-test --attention-pytorch --all-in-fp16 --always-high-vram --use-cpu interrogate\""
          patch_file "https://raw.githubusercontent.com/viking1304/a1111-setup/main/patches/lineargs-arm-f.patch" "75b2bf86ba0c7b73658ad9d22d62444affc7af61c904364bff0e88975e8af905"
        fi
      else
        msg " for Macs with less than 16 GB of RAM"
        if [[ "${fork}" == "a1111" ]]; then
          msg "COMMANDLINE_ARGS=\"--skip-torch-cuda-test --opt-sub-quad-attention --upcast-sampling --no-half-vae --lowvram --use-cpu interrogate\""
          patch_file "https://raw.githubusercontent.com/viking1304/a1111-setup/main/patches/lineargs-lowvram.patch" "fa102780cc830eefd576cbec43f6b416c02f27e4347851f82d143065ea686bd4"
        fi
        if [[ "${fork}" == "forge" ]]; then
          msg "COMMANDLINE_ARGS=\"--skip-torch-cuda-test --attention-pytorch --all-in-fp16 --use-cpu interrogate\""
          patch_file "https://raw.githubusercontent.com/viking1304/a1111-setup/main/patches/lineargs-lowvram-f.patch" "2b06015a393804db584a2a91ef56f1a0727f63fc93e44821471f7b4b8cca6550"
        fi
      fi
    else
      msg_cn "Applying patch: " "Set recommended command line args for Intel"
      msg "COMMANDLINE_ARGS=\"--skip-torch-cuda-test --opt-sub-quad-attention --upcast-sampling --no-half --lowvram --use-cpu interrogate\""
      patch_file "https://raw.githubusercontent.com/viking1304/a1111-setup/main/patches/lineargs-intel.patch" "62ba57613211b41ae4c505d896f88be590348f759b746bf469a8df4cdaf314aa"
    fi
    msg_br
  fi

  # set command line args for VM
  if [[ "${vm}" == true ]]; then
    msg_cn "Applying patch: " "Set working command line args for VM"
    msg "COMMANDLINE_ARGS=\"--skip-torch-cuda-test --opt-sub-quad-attention --upcast-sampling --no-half --lowvram --use-cpu all\""
    patch_file "https://raw.githubusercontent.com/viking1304/a1111-setup/main/patches/lineargs-vm.patch" "c48fdeedfa8c370b789bcc21bdac73b34b3bd603559d0bead9d30d37f791d0d8"
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

cleanup() {
  if [[ -n "$SUDO_KEEP_ALIVE_PID" ]]; then
    if [[ "${debug}" == true ]]; then
      msg_nc "Stopping keep_sudo_alive process with PID: " "$SUDO_KEEP_ALIVE_PID"
    fi
    kill "$SUDO_KEEP_ALIVE_PID" 2>/dev/null
  fi
}

main() {
  # execute cleanup function on EXIT
  trap cleanup EXIT

  # display blank line
  msg_br

  # exit script if not run on macOS
  if [[ "$(uname -s)" != "Darwin" ]]; then
    err_msg "This script can only be used on macOS!"
    exit 1
  fi

  # find the directory where the script is located
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  # parse command line arguments
  parase_command_line_arguments "$@"

  # show welcome message
  welcome_message

  # get basic system info
  get_basic_system_info

  # get brew info
  get_brew_info

  # set the repository, branch and destination folder
  set_repo_and_dest_dir

  # show debug info
  if [[ "${debug}" == true ]]; then
    debug_info
  fi

  # show system info and python versions
  if [[ "${show_info}" == true || "${debug}" == true ]]; then
    show_sys_info
    msg_br
    show_python_versions
    msg_br
    show_brew_info
    msg_br
  fi

  if [[ "${brew_info}" == "Intel" && "${cpu}" == "arm" ]]; then
    if [[ "${show_info}" == true ]]; then
      warn_msg "You are using Homebrew for ${!color}Intel${nc} on ${!color}ARM${nc} CPU!"
      msg "You will not be able to properly install Stable Diffusion using this script."
      msg_br
    else
      err_msg "You are using Homebrew for ${!color}Intel${nc} on ${!color}ARM${nc} CPU!"
      msg "Please completely remove your current Homebrew installation before running this script again."
      msg_br
      exit 1
    fi
  fi

  # exit after showing info
  if [[ "${show_info}" == true ]]; then
    exit 0
  fi

  # do not ask for password upfront, because of recent Homebrew changes 
  # https://github.com/orgs/Homebrew/discussions/5528

  # check if sudo requires a password and ask user to enter it if necessary
  # is_password_required
  # keep-alive by updating existing 'sudo' time stamp until script has finished
  # keep_sudo_alive

  # install Homebrew
  install_homebrew

  # install required packages
  install_required_packages

  # (re)install A1111 or Forge
  install_webui

  # apply patches
  apply_patches

  # set extensions folder
  ext="${dest_dir}/extensions"

  # install extensions
  install_extensions

  # restore settings
  restore_settings

  # run webui
  msg_nc "Starting " "${fork}"
  if [[ "${dry_run}" != true ]]; then
    ./webui.sh
  else
    dry_msg "./webui.sh"
  fi
}

# set debug mode
# debug=true
# ignore_vm=true

main "$@"