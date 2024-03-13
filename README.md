# a1111-setup
**Simple and easy way to install Automatic1111 WebUI or Forge on Mac**

By default, this script will install A1111 in  `stable-diffusion-webui` inside your home directory, but you can change the location if you want.

The script will apply some recommended fixes and install the required libraries. If there is already an installation in that folder, the script will purge the pip cache, remove venv, and force using the latest version of A1111. A new venv will be created, and you should be able to use A1111 on your Mac without any problems.

Simply run `bash a1111-setup.sh` or `chmod 755 a1111-setup.sh && ./a1111-setup.sh`. Wait a few minutes (depending on your computer and internet speed) until you see WebUI opened in your default browser.

Command line parameters:

```
      [-t stable|develop] stable or develop version of PyTorch
      [-f all|errors|none] apply all fixes, only fixes for errors or none
      [-d folder_name] specify the destination folder for A1111 installation
      [-o a1111|forge] install A1111 or Forge 
      [-b] update Homebrew
      [-h] display help
```

The [latest stable release](https://github.com/pytorch/pytorch/releases) of PyTorch will be installed by default, which is now recommended for Macs. It is still possible to use the development version using the `-t develop` option, but it is not necessary anymore.

Only errors will be fixed by default, but you can also apply command line param tweak using `-f all`. Based on my tests, those parameters give a better and faster performance of A1111 WebUI than those provided by the A1111 team.

Use option `-d` to specify the destination folder for A1111 installation or the folder where A1111 is currently installed.

Use option `-o` to specify which webui to install. You can choose between A1111 and Forge.

Since some people might not want to update their installation of Homebrew, the update is disabled by default, but you can update brew using the `-b` option.

**Additional Notes**

In some extremely rare cases, default command line parameters provided by the A1111 team might not work correctly, for example, with some Macs with eGPU.

You can try and see which of the command line parameters below works the best for you.

Args for Macs implemented by the A1111 team:
```
export COMMANDLINE_ARGS="--skip-torch-cuda-test --upcast-sampling --no-half-vae --use-cpu interrogate"
```

My recommendation for most Macs:
```
export COMMANDLINE_ARGS="--skip-torch-cuda-test --opt-sub-quad-attention --upcast-sampling --no-half-vae --medvram-sdxl --use-cpu interrogate"
```

My recommendation for Macs with 36GB or more RAM:
```
export COMMANDLINE_ARGS="--skip-torch-cuda-test --opt-sub-quad-attention --upcast-sampling --no-half-vae --use-cpu interrogate"
```

In some extremely rare cases, WebUI might produce only noise with   `--no-half-vae`. *I have never noticed that, but some people with external GPUs and two nonstandard AMD GPUs had that problem.*
```
export COMMANDLINE_ARGS="--skip-torch-cuda-test --upcast-sampling --no-half --use-cpu interrogate"
export COMMANDLINE_ARGS="--skip-torch-cuda-test --opt-sub-quad-attention --upcast-sampling --no-half --medvram-sdxl"
```

Those combinations also worked without error on my Macs:
```
export COMMANDLINE_ARGS="--skip-torch-cuda-test --opt-split-attention-v1 --opt-sub-quad-attention --upcast-sampling --no-half-vae --medvram-sdxl"
export COMMANDLINE_ARGS="--skip-torch-cuda-test --upcast-sampling --no-half-vae --medvram-sdxl"
export COMMANDLINE_ARGS="--skip-torch-cuda-test --opt-split-attention-v1 --upcast-sampling --no-half-vae --medvram-sdxl"
export COMMANDLINE_ARGS="--skip-torch-cuda-test --opt-sub-quad-attention --upcast-sampling --no-half-vae --medvram"
```

*All comments and suggestions are welcome*

3 min read
