# a1111-setup
Simple Automatic1111 install script for Mac

It will install A1111 in `stable-diffusion-webui` inside your home directory.

Script will apply some recommended fixes and install required libraries. If there is already an installation in that folder, script will purge pip cache, remove venv, and force using of latest version of A1111. New venv will be created and you should be able to use A1111 on your Mac without any problems.

Simply run `sh a1111-setup.sh` or `chmod 755 a1111-setup.sh && ./a1111-setup.sh`. Wait a few minutes (depending on your computer and internet speed) until you see webui opened in your default browser.

I have added a few command line parameters:

```
      [-t stable|develop] stable or develop version of PyTorch
      [-f all|errors|none] apply all fixes, only fixes for errors or none
      [-b] update Homebrew
      [-h] display help
```

New stable release of [PyTorch 2.1.2 is released](https://github.com/pytorch/pytorch/releases/tag/v2.1.2), and that is now a recommended version for Macs since it has some MPS(metal) and AArch64(silicon) fixes. This version will be installed by default. It is still posible to use development version using `-t develop` option.

By default only errors will be fixed, but you can also aplly command line param tweak using `-f all`. This option was added since some Macs with spefic hardware are not working properly with command paramaters that works the best on most Macs.

Since some people might not want to update brew, update is disabled by default, but you can update brew using `-b` option.

**Note:** you can try and see which of the command line parameters below works the best for you.

Args for Macs implemented by A1111 team:
```
export COMMANDLINE_ARGS="--skip-torch-cuda-test --upcast-sampling --no-half-vae --use-cpu interrogate"
```

My recommendation for most Macs:
```
export COMMANDLINE_ARGS="--skip-torch-cuda-test --opt-sub-quad-attention --upcast-sampling --no-half-vae --medvram-sdxl --use-cpu interrogate"
```

For special cases when `--no-half-vae` produce only noise:
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

*All comments and sugestions are wellcome*
