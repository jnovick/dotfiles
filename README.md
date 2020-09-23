# dotfiles

- To get best Windows Terminal experience, I first install these steps by hand:

  1. Install WSL by running this in powershell as admin. [Official MS Docs](https://docs.microsoft.com/en-us/windows/wsl/install-win10)

  ```powershell
  dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
  dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
  ```

  1. Download and install kernel update <https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi>
  1. Follow Instructions I wrote when I did upgrade to WSL2 from WSL1: [WSL2 Upgrade Steps](./docs/WSL2UpgradeSteps.md)
      - Skip any steps that set up the dotfiles or install software (Except .ssh folder)
      - TODO: Remove those steps later
      - TODO: Automate and streamline more

- Clone git repo
  - Clone must happen on linux file system not Windows unless [mount options](https://docs.microsoft.com/en-us/windows/wsl/wsl-config#mount-options)
  have been enabled in `/etc/wsl.conf`. Example settings below, but I recommend still using the linux side.

    ``` conf
    [automount]
    options = "metadata,umask=22,fmask=11"
    ```

  - Setup the [git credential manager](https://github.com/microsoft/Git-Credential-Manager-for-Windows/releases) before cloning

    ``` bash
    git config --global credential.helper "/mnt/c/Program\\ Files/Git/mingw64/libexec/git-core/git-credential-manager.exe"
    git clone https://gitlab.infiniteenergy.dev/Jdnovick/dotfiles.git
    git config --global --unset credential.helper && grep -q '[^[:space:]]' < ~/.gitconfig || rm ~/.gitconfig
    ```

- Install dotfiles
  - This can be re-run many times safely to link new files added to repo
  - If the dotfiles already exist, the script will rename them with `.<Date-Time>.bak` appended to the end

  ``` bash
  chmod +x install-dotfiles.bash
  ./install-dotfiles.bash

  # Alternatively, instead of using chmod, you could do:
  bash install-dotfiles.bash
  ```

- Install desired software
  - This will prompt you for your password up to two times and approve switching default shell to zsh

``` bash
bash ./install-software.bash
```
