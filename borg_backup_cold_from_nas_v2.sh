#!/usr/bin/env bash

echo "$(date): Skript wurde getriggert" >> /var/log/dispatcher.log

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Überprüfen, ob der Backup-Server erreichbar ist (egal ob per WLAN oder VPN)
# ping -c 1 ubuntu-vm &> /dev/null
# if [ $? -ne 0 ]; then
#     echo "Backup-Server nicht erreichbar. Backup wird nicht gestartet."
#     exit 0
# fi


export BORG_REPO='/run/media/murmeldin/backup_cold/borg'
#export BORG_RSH='ssh -i /home/murmeldin/.ssh/id_ed25519_backup'

# Setting this, so you won't be asked for your repository passphrase:
#read -s -p "Repo passphrase : " PASSPHRASE
export BORG_PASSPHRASE=Vegan-King-Doctrine-Imagines9-Drained
# or this to ask an external program to supply the passphrase:
#export BORG_PASSCOMMAND='pass show backup'

# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$( date )" "$*" >&2; }
trap 'echo $( date ) Backup interrupted >&2; exit 2' INT TERM

info "Starting backup"

# Backup the most important directories into an archive named after
# the machine this script is currently running on:

borg create                         \
    --verbose                       \
    --filter AME                    \
    --list                          \
    --stats                         \
    --progress                      \
    --show-rc                       \
    --compression none              \
    --exclude-caches                \
    --exclude '/home/*/.cache/*'    \
    --exclude '/home/murmeldin/.dotfiles' \
    --exclude '/var/cache/*'        \
    --exclude '/var/tmp/*'          \
    --exclude '/home/murmeldin/VirtualBox VMs/*' \
    --exclude '/home/murmeldin/go/*' \
    --exclude '/home/murmeldin/SteamGames/*' \
                                    \
    ::'{hostname}-{now}'            \
    /run/media/murmeldin/Sicherung5TB   \

backup_exit=$?

info "Pruning repository"

# Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
# archives of THIS machine. The '{hostname}-' prefix is very important to
# limit prune's operation to this machine's archives and not apply to
# other machines' archives also:

borg prune                          \
    --list                          \
    --glob-archives '{hostname}-*'  \
    --show-rc                       \
    --keep-daily    7               \
    --keep-weekly   4               \
    --keep-monthly  6               \

prune_exit=$?

# use highest exit code as global exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))

if [ ${global_exit} -eq 1 ];
then
    info "Backup and/or Prune finished with a warning"
fi

if [ ${global_exit} -gt 1 ];
then
    info "Backup and/or Prune finished with an error"
fi

exit ${global_exit}