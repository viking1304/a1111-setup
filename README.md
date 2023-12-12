# a1111-setup
Simple Automatic1111 install script for Mac

It will install A1111 in `stable-diffusion-webui` inside your home directory.

Script will apply some recommended fixes and install required libraries. If there is already an installation in that folder, script will purge pip cache, remove venv, and force using of latest version of A1111. New venv will be created and you should be able to use A1111 on your Mac without any problems.

Simply run `sh a1111-setup.sh` or `chmod 755 a1111-setup.sh && ./a1111-setup.sh`. Wait a few minutes (depending on your computer and internet speed) until you see webui opened in your default browser.

*All comments and sugestions are wellcome*
