#!/bin/bash

echo "Backup started at $(date '+%T')"

export BACKUP_PATH="/tmp/backup-$(date +%F)"
export RCLONE_CONFIG_NAME=''
export BUCKET_NAME=''

mkdir $BACKUP_PATH

echo '[Nextcloud] Turning on maintenance mode'
docker exec --user www-data nextcloud php occ maintenance:mode --on

echo '[Vaultwarden] Taking service down'
docker stop vaultwarden

echo '[Backup] Backing up databases'
mysqldump --single-transaction --default-character-set=utf8mb4 -h localhost -u root --databases nextcloud vaultwarden > "$BACKUP_PATH/mysql.sql"

echo '[Backup] Creating encrypted archive'
tar cf - -C / var/nextcloud var/vaultwarden "${BACKUP_PATH:1}/mysql.sql" | pigz | openssl enc -pass file:/root/.passwd -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -out "$BACKUP_PATH/backup.tar.gz.aes" 

echo '[Backup] Uploading archive'
rclone move "$BACKUP_PATH/backup.tar.gz.aes" "$RCLONE_CONFIG_NAME:$BUCKET_NAME/$(date +%F)"

echo '[Nextcloud] Turning off maintenance mode'
docker exec --user www-data nextcloud php occ maintenance:mode --off

echo '[Vaultwarden] Bringing service up'
docker start vaultwarden

echo '[Backup] Cleaning up'
rm -rf $BACKUP_PATH

echo "Finished at $(date '+%T')"
