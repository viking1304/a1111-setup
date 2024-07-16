# Install Stable Diffusion WebUI on Mac
**Simple and easy Automatic1111 and Forge install script for macOS**

By default, this script will install **Stable Diffusion WebUI** (Automatic1111) in  `stable-diffusion-webui` inside your home directory, but you can change the location if you want.

The script will apply some recommended fixes and install the required libraries. If an installation is already in that folder, the script will purge the pip cache, remove venv, and force the latest version of Stable Diffusion WebUI to be used. A new venv will be created, and you should be able to use Stable Diffusion WebUI on your Mac without any problems.

Run `sh a1111-setup.sh` or make the script executable with `chmod 755 a1111-setup.sh` and then run `./a1111-setup.sh`. Wait a few minutes (depending on your computer and internet speed) until you see WebUI opened in your default browser.

Command line parameters:

```
      [-h] display help
      [-r] dry run, only show what would be done
      [-b] update Homebrew
      [-t] use development version of PyTorch
      [-i] show debug info and exit
      [-f all|none] apply all fixes or none
      [-d folder_name] specify the destination folder for WebUI installation
      [-o forge] install Forge
      [-c red|green|yellow|blue|magenta|cyan|no-color] use specified color theme for messages
```

The recommended version of PyTorch will be automatically installed. At this moment, it is 2.3.1 for ARM and 2.1.2 for Intel. The development version of PyTorch can still be used with the `-t develop` option, but only on ARM Macs.

*PyTorch dropped support for Intel Macs. The last version of PyTorch that properly works on Intel Macs with MacOS 14.4+ is 2.1.2*

Fixes for very rare errors will not be applied by default. You can use `-f all` to apply them.

Use option `-d` to specify the destination folder for WebUI installation or the folder where WebUI is currently installed.

Even though [the Forge team advised users to change back to A1111](https://github.com/lllyasviel/stable-diffusion-webui-forge/discussions/801), it is still possible to install Forge using `-o forge` if you need it.

Since some people might not want to update their Homebrew installation, the update is disabled by default, but you can update it using the `-b` option.

By default, script use a blue color theme, but you can change it using `-c` option. For example, you can use `-c green` to use green color theme.

The new  `-i` option will show debug info and exit. This information might be helpful when you report a problem.

**Additional Notes**

In some extremely rare cases, WebUI might produce only noise with  `--no-half-vae`. *I have never noticed that, but some people with external GPUs and two nonstandard AMD GPUs had that problem.*

If you experience that problem, you can try one of those command line args:

```
export COMMANDLINE_ARGS="--skip-torch-cuda-test --upcast-sampling --no-half --use-cpu interrogate"
export COMMANDLINE_ARGS="--skip-torch-cuda-test --opt-sub-quad-attention --upcast-sampling --no-half --medvram-sdxl"
```

*All comments and suggestions are welcome*

3 min read
