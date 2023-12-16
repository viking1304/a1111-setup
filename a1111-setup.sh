#!/usr/bin/env bash

# File: a1111-setup.sh
#
# Usage: a1111-setup.sh
#
# Description: Simple A1111 install script for Mac.
# It will install A1111 in stable-diffusion-webui inside your home directory.
#
# Options: ---
# Requirements: MacOS
# Bugs: ---
# Notes: ---
# Author: Aleksandar Milanovic (viking1304)
# Version: 0.0.2
# Created: 2023/12/12 19:30:51
# Last modified: 2022/16/12 16:00:07

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

# install stable version of PyTorch and only fix errors by default
update_brew=false
torch="stable"
fix="errors"

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
  echo "\nDetecting processor..."
  if [[ "$(sysctl -n machdep.cpu.brand_string)" =~ ^.*"Apple".*$ ]]; then
    echo "ARM processor detected\n"

    # temporary add Brew to path on ARM
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  if [[ "$(sysctl -n machdep.cpu.brand_string)" =~ ^.*"Intel".*$ ]]; then
      echo "Intel processor detected\n"
  fi
}

install_a1111() {
  # go to home folder
  cd
  # check if destination folder exists
  if [[ ! -d "stable-diffusion-webui" ]]; then
    echo "\nNew installation. Cloning A1111..."
    # clone automatic1111
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui
    cd stable-diffusion-webui
  else
    echo "\nExisting installation detected..."
    cd stable-diffusion-webui
    # force A1111 upgrade
    if [[ -d ".git" ]]; then
      echo "Forcing A1111 upgrade..."
      git reset --hard origin/master
      git pull
    else
      echo "\nCurrent version is not installed using git!\nPlease rename or remove folder ${HOME}/stable-diffusion-webui and try again"
      exit 1
    fi
    # purge pip cache
    if [[ -f "venv/bin/pip" ]]; then  
      echo "Purging pip cache..."
      venv/bin/pip cache purge
    fi
    # remove venv
    if [[ -d "venv" ]]; then  
      echo "Removing venv..."
      rm -rf venv
    fi
  fi
}

brew_install() {
    echo "Installing $1..."
    if brew list $1 &>/dev/null; then
        echo "${1} is already installed"
    else
        brew install $1 && echo "$1 is installed"
    fi
}

apply_fixes() {
  if [[ "$torch" == "develop" ]]; then
    echo "\nInstruct A1111 to use development version of torch..."
    sed -i '' 's/#export TORCH_COMMAND="pip install torch==1.12.1+cu113 --extra-index-url https:\/\/download.pytorch.org\/whl\/cu113"/#export TORCH_COMMAND="pip install torch==1.12.1+cu113 --extra-index-url https:\/\/download.pytorch.org\/whl\/cu113"\nexport TORCH_COMMAND="pip install --pre torch torchvision torchaudio --index-url https:\/\/download.pytorch.org\/whl\/nightly\/cpu"/' webui-user.sh
  else
    echo "\nInstruct A1111 to use latest stable version of torch..."
    sed -i '' 's/#export TORCH_COMMAND="pip install torch==1.12.1+cu113 --extra-index-url https:\/\/download.pytorch.org\/whl\/cu113"/#export TORCH_COMMAND="pip install torch==1.12.1+cu113 --extra-index-url https:\/\/download.pytorch.org\/whl\/cu113"\nexport TORCH_COMMAND="pip install torch torchvision torchaudio"/' webui-user.sh
  fi
  if [[ "$fix" == "all" ]]; then
    echo "Add recommended command line parameters..."
    sed -i '' 's/#export COMMANDLINE_ARGS=""/#export COMMANDLINE_ARGS=""\nexport COMMANDLINE_ARGS="--skip-torch-cuda-test --opt-sub-quad-attention --upcast-sampling --no-half-vae --medvram-sdxl"/' webui-user.sh
  fi
  if [[ "$fix" == "all" || "$fix" == "errors" ]]; then
    echo "Fix cannot convert a MPS Tensor to float64 dtype error..."
    sed -i '' "/^                    dtype = sd_param.dtype if sd_param is not None else param.dtype/,/^ *[^:]*:/s/module._parameters\[name\] = torch.nn.parameter.Parameter/if dtype == torch.float64 and device.type == 'mps':\n                      dtype = torch.float32\n                    module._parameters\[name\] = torch.nn.parameter.Parameter/" modules/sd_disable_initialization.py
  fi
}

parase_parameters() {
  usage() { echo "$0 usage:" && grep "[[:space:]].)\ #" $0 | sed 's/#//' | sed -r 's/([a-z])\) /[-\1/'; exit 0; }
  #(( $# == 0 )) && usage
  while getopts ":hbt:f:" arg; do
    case $arg in
      t) # stable|develop] stable or develop version of PyTorch
        torch=${OPTARG}
        if [[ "$torch" != "stable"  && "$torch" != "develop" ]]; then
          echo "parameter -t must either be stable or develop"
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
      b) #] update Homebrew
        update_brew=true
        ;;
      h) #] display help
        usage
        exit 0
        ;;
    esac
  done
}

main() {
  # Exit script if not run on macOS
  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This script can only be used on macOS!"
    exit 1
  fi  

  parase_parameters "$@"

  # Ask for user password upfront (with custom prompt)
  sudo -v -p "Please enter password for user '%p': "

  # Keep-alive by updating existing 'sudo' time stamp until script has finished
  while true; do access_check; sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

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

  # (re)intall a1111
  install_a1111
  
  # apply some fixes
  apply_fixes

  # run webui
  ./webui.sh

  echo ""
}

main "$@"