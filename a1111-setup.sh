#!/usr/bin/env bash

# File: a1111-setup.sh
#
# Usage: a1111-setup.sh
#
# Description: Simple and easy way to install Automatic1111 WebUI or Forge on Mac
#
# Options: ---
# Requirements: MacOS
# Bugs: ---
# Notes: ---
# Author: Aleksandar Milanovic (viking1304)
# Version: 0.1.0
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

readonly VERSION='0.1.0'
readonly YEAR='2024'

# install recommended version of PyTorch and only fix errors by default
update_brew=false
torch="recommended"
fix="errors"
fork="a1111"

# webui repos and default destination folders
a1111_repo="https://github.com/AUTOMATIC1111/stable-diffusion-webui.git"
a1111_df="${HOME}/stable-diffusion-webui"
forge_repo="https://github.com/lllyasviel/stable-diffusion-webui-forge.git"
forge_df="${HOME}/stable-diffusion-webui-forge"

# Install Homebrew
install_homebrew() {
  echo "Checking for Homebrew..."
  if [[ -z "$(which brew)" ]]; then
    echo "Installing Homebrew..."
    echo | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    if [[ $update_brew == true ]]; then
      brew update
      brew upgrade
    fi
  fi
}

detect_cpu() {
  echo -e "\nDetecting processor..."
  if [[ "$(sysctl -n machdep.cpu.brand_string)" =~ ^.*"Apple".*$ ]]; then
    echo -e "ARM processor detected\n"

    # temporary add Brew to path on ARM
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  if [[ "$(sysctl -n machdep.cpu.brand_string)" =~ ^.*"Intel".*$ ]]; then
      echo -e "Intel processor detected\n"
  fi
}

install_webui() {
  # check if destination folder exists
  if [[ ! -d "$df" ]]; then
    echo -e "\nInstalling webui into $df\n"
    # clone automatic1111

    if ! git clone "$repo" "$df"; then
      exit 1
    else
      # shellcheck disable=SC2164
      cd "$df"
    fi
  else
    if [[ "$(ls -A "$df")" ]]; then
      echo -e "\nUpdating webui installation in $df\n"
    else
      echo -e "\nInstalling webui into $df\n"
    fi
    # shellcheck disable=SC2164
    cd "$df"
    # force webui upgrade
    if [[ -d ".git" ]]; then
      git reset --hard origin/master
    else
      git init
      git remote add origin "$repo"
      git fetch --all
      git reset --hard origin/master
      git branch --set-upstream-to=origin/master master
    fi
    git pull
    if [[ "$(git status | grep modified)" != "" ]]; then
      echo -e "\nERROR: some webui files are still modifed"
      show_modified
      exit 1
    fi
    # purge pip cache
    if [[ -f "venv/bin/pip" ]]; then  
      echo -e "\nPurging pip cache..."
      venv/bin/pip cache purge
    fi
    # remove venv
    if [[ -d "venv" ]]; then  
      echo -e "\nTrying to remove venv..."
      rm -rf venv 2> /dev/null
        if [[ ! -d "venv" ]]; then
          echo "Successfully removed venv"
        else
          echo -e "Could not remove venv\nTrying to remove venv using admin privileges..."
          sudo rm -rf venv 2> /dev/null
          if [[ ! -d "venv" ]]; then
            echo "Successfully removed venv using admin privileges"
          else
            echo "ERROR: could not remove venv even using admin privileges"
            exit 1
          fi
        fi
    fi
  fi
}

brew_install() {
    echo "Installing $1..."
    if brew list "$1" &>/dev/null; then
        echo "$1 is already installed"
    else
        brew install "$1" && echo "$1 is installed"
    fi
}

set_torch_version(){
  if [[ "$torch" == "develop" || "$torch" == "recommended" ]]; then
    echo -e "\nInstruct webui to use development version of torch..."
    sed -i '' 's/#export TORCH_COMMAND="pip install torch==1.12.1+cu113 --extra-index-url https:\/\/download.pytorch.org\/whl\/cu113"/#export TORCH_COMMAND="pip install torch==1.12.1+cu113 --extra-index-url https:\/\/download.pytorch.org\/whl\/cu113"\nexport TORCH_COMMAND="pip install --pre torch torchvision --index-url https:\/\/download.pytorch.org\/whl\/nightly\/cpu"/' webui-user.sh
  fi
  if [[ "$torch" == "stable" ]]; then
    echo -e "\nInstruct webui to use latest stable version of torch..."
    sed -i '' 's/#export TORCH_COMMAND="pip install torch==1.12.1+cu113 --extra-index-url https:\/\/download.pytorch.org\/whl\/cu113"/#export TORCH_COMMAND="pip install torch==1.12.1+cu113 --extra-index-url https:\/\/download.pytorch.org\/whl\/cu113"\nexport TORCH_COMMAND="pip install torch torchvision"/' webui-user.sh
  fi
}

apply_fixes() {
  if [[ "$fix" == "all" || "$fix" == "errors" ]]; then
    if [[ "$torch" == "stable" ]]; then
      echo -e "\nFix Contolnet requirements hell..."
      sed -i '' 's/httpx==0.24.1/httpx==0.24.1\nprotobuf==3.20.3\ninsightface==0.7.3/' requirements_versions.txt
    fi
    echo "Fix cannot convert a MPS Tensor to float64 dtype error..."
    sed -i '' "/^                    dtype = sd_param.dtype if sd_param is not None else param.dtype/,/^ *[^:]*:/s/module._parameters\[name\] = torch.nn.parameter.Parameter/if dtype == torch.float64 and device.type == 'mps':\n                      dtype = torch.float32\n                    module._parameters\[name\] = torch.nn.parameter.Parameter/" modules/sd_disable_initialization.py
  fi
  if [[ "$fix" == "all" ]]; then
    echo -e "\nAdd recommended command line parameters..."
    if [[ "$fork" == "forge" ]]; then
      sed -i '' 's/#export COMMANDLINE_ARGS=""/#export COMMANDLINE_ARGS=""\nexport COMMANDLINE_ARGS="--skip-torch-cuda-test --attention-pytorch --all-in-fp16 --always-high-vram --use-cpu interrogate"/' webui-user.sh
    fi
    if [[ "$fork" == "a1111" ]]; then
      sed -i '' 's/#export COMMANDLINE_ARGS=""/#export COMMANDLINE_ARGS=""\nexport COMMANDLINE_ARGS="--skip-torch-cuda-test --opt-sub-quad-attention --upcast-sampling --no-half-vae --use-cpu interrogate"/' webui-user.sh
    fi
  fi
  show_modified
}

parase_parameters() {
  usage() { echo "$0 usage:" && grep "[[:space:]].)\ #" "$0" | sed 's/#//' | sed -r 's/([a-z])\) /[-\1/'; exit 0; }
  #(( $# == 0 )) && usage
  while getopts ":hbt:f:d:o:" arg; do
    case $arg in
      t) # recommended|stable|develop] recommended, stable or develop version of PyTorch
        torch=${OPTARG}
        if [[ "$torch" != "recommended" && "$torch" != "stable" && "$torch" != "develop" ]]; then
          echo "parameter -t must be recommended, stable or develop"
          exit 1
        fi
        ;;
      f) # all|errors|none] apply all fixes, only fixes for errors or none
        fix=${OPTARG}
        if [[ "$fix" != "all"  && "$fix" != "errors" && "$fix" != "none" ]]; then
          echo "parameter -f must be all, errors or none"
          exit 1
        fi
        ;;
      d) # folder_name] specify the destination folder for webui installation
        df=${OPTARG}
        # treat destination as subfolder of home directory, unless it starts with slash
        if [[ "${df:0:1}" != '/' ]]; then
          df="$HOME/$df"
        fi
        # remove trailing slash
        df=${df%/}
        ;;
      o) # a1111|forge] install A1111 or Forge
        fork=${OPTARG}
        if [[ "$fork" != "forge"  && "$fork" != "a1111" ]]; then
          echo "parameter -o must be a1111 or forge"
          exit 1
        fi
        ;;
      b) #] update Homebrew
        update_brew=true
        ;;
      h) #] display help
        usage
        ;;
      *)  # unknown params handler
        usage
        ;;
    esac
  done
}

show_modified() {
  echo -e "\nList of modified files:"
  git status | grep modified | sed 's/	modified: //'
}

main() {
  # Exit script if not run on macOS
  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This script can only be used on macOS!"
    exit 1
  fi

  interpreter=$(ps h -p $$ -o args='' | cut -f1 -d' ')
  # Exit script if not run with bash
  if [[ "$interpreter" != "bash" ]]; then
    echo "This script requires bash to work properly!"
    exit 1
  fi

  source_dir=$(realpath "$(dirname "${BASH_SOURCE[0]}")")

  echo -e "\n-----------------------------------\n"
  echo -e " A1111-setup v$VERSION\n Copyright (c) $YEAR\n Aleksandar Milanovic (viking1304)\n"
  echo -e "-----------------------------------\n"

  parase_parameters "$@"

  # Ask for user password upfront (with custom prompt)
  sudo -v -p "Please enter password for user '%p': "

  # Keep-alive by updating existing 'sudo' time stamp until script has finished
  while true; do access_check; sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

  # use a1111 repo by default
  repo="$a1111_repo"

  # set the repo based on fork
  if [[ "$fork" == "forge" ]]; then
    repo="$forge_repo"
  fi

  # if destination folder is not set use the default location based on fork
  if [[ -z "$df" ]]; then
    if [[ "$fork" == "forge" ]]; then
      df="$forge_df"
    else
      df="$a1111_df"
    fi
  fi

  # Install Homebrew
  install_homebrew

  # Temporary fix Brew path on ARM devices
  detect_cpu

  # install required packages
  echo "Checking for required packages..."
  brew_install cmake
  brew_install protobuf 
  brew_install rust 
  brew_install python@3.10 
  brew_install git 
  brew_install wget

  # (re)install webui
  install_webui

  # set torch version
  set_torch_version

  # apply some fixes
  apply_fixes

  # run webui
  echo -e "\n----------------------------------------------------------------\n"
  echo -e "\nLaunching webui..."
  ./webui.sh

  echo ""
}

main "$@"