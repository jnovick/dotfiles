wsl.exe --set-default-version 2
wsl.exe --set-default Ubuntu-20.04
wsl.exe --set-version Ubuntu-20.04 2
wsl.exe bash -c "cd ~ && \
git clone -c credential.helper='/mnt/c/Program\\ Files/Git/mingw64/libexec/git-core/git-credential-manager.exe' https://gitlab.infiniteenergy.dev/Jdnovick/dotfiles.git && \
cd dotfiles && git config --unset credential.helper && \
bash install-dotfiles.bash && \
bash install-software.bash"