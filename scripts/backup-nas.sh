#!/bin/bash
LOG="/var/log/nas-backup.log"
SOURCE="/mnt/nas-hdd/"
DEST="/mnt/storage/"
THRESHOLD=90
TELEGRAM_TOKEN="YOUR_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"

notify() {
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
    -d chat_id="${CHAT_ID}" \
    -d text="$1" > /dev/null
}

echo "$(date) --- Backup Started ---" >> $LOG

USAGE=$(df /mnt/storage | awk 'NR==2 {print $5}' | tr -d '%')
if [ "$USAGE" -gt "$THRESHOLD" ]; then
    echo "$(date) WARNING: Backup drive is ${USAGE}% full! Backup aborted." >> $LOG
    notify "⚠️ piserver: Backup drive is ${USAGE}% full! Backup aborted."
    exit 1
fi

rsync -av --no-perms --no-owner --no-group /mnt/nas-hdd/ /mnt/storage/ >> $LOG 2>&1

echo "$(date) --- Backup Completed ---" >> $LOG
notify "✅ piserver: Weekly backup completed successfully."
