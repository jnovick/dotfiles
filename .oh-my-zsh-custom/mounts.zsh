# sudo mount U: /mnt/u -t drvfs -o metadata,umask=22,fmask=11,uid=1000,gid=1000 2> /dev/null
[[ -d "/mnt/c" && -d "/c" ]] && sudo mount --bind /mnt/c /c
