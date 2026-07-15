#!/bin/bash
TELEGRAM_TOKEN="YOUR_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"
STATE_DIR="/var/lib/pimonitor"
mkdir -p $STATE_DIR

send_message() {
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
    -d chat_id="${CHAT_ID}" \
    -d text="$1" > /dev/null
}

alert_once() {
    KEY="$1"
    MSG="$2"
    FILE="$STATE_DIR/$KEY"
    if [ ! -f "$FILE" ]; then
        send_message "$MSG"
        touch "$FILE"
    fi
}

clear_alert() {
    rm -f "$STATE_DIR/$1"
}

for dev in sda sdb sdc; do
    TEMP=$(smartctl -A /dev/$dev 2>/dev/null | grep -i "Temperature_Celsius" | awk '{print $10}')
    if [ -n "$TEMP" ]; then
        if [ "$TEMP" -gt 55 ]; then
            alert_once "temp_$dev" "🌡️ WARNING: /dev/$dev temperature is ${TEMP}C - above 55C!"
        else
            clear_alert "temp_$dev"
        fi
    fi
done

CPU_TEMP=$(vcgencmd measure_temp | grep -o '[0-9]*\.[0-9]*' | cut -d. -f1)
if [ "$CPU_TEMP" -gt 75 ]; then
    alert_once "cpu_temp" "🔥 WARNING: CPU temperature is ${CPU_TEMP}C - above 75C!"
else
    clear_alert "cpu_temp"
fi

LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)
LOAD_INT=$(echo $LOAD | cut -d. -f1)
if [ "$LOAD_INT" -gt 3 ]; then
    alert_once "cpu_load" "📊 WARNING: High CPU load detected: $LOAD"
else
    clear_alert "cpu_load"
fi

for mount in /mnt/nas-hdd /mnt/media-ssd /mnt/storage; do
    NAME=$(echo $mount | tr '/' '_')
    USAGE=$(df $mount 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%')
    if [ -n "$USAGE" ]; then
        if [ "$USAGE" -gt 80 ]; then
            alert_once "usage$NAME" "💾 WARNING: $mount is ${USAGE}% full!"
        else
            clear_alert "usage$NAME"
        fi
    fi
done

for mount in /mnt/nas-hdd /mnt/media-ssd /mnt/storage; do
    NAME=$(echo $mount | tr '/' '_')
    if ! mountpoint -q $mount; then
        alert_once "mount$NAME" "❌ ALERT: $mount is NOT mounted!"
    else
        clear_alert "mount$NAME"
    fi
done

if ! docker ps | grep -q jellyfin; then
    alert_once "jellyfin_down" "❌ ALERT: Jellyfin container is DOWN!"
else
    clear_alert "jellyfin_down"
fi

LAST_BACKUP_LINE=$(grep "Backup Completed" /var/log/nas-backup.log 2>/dev/null | tail -1)
if [ -n "$LAST_BACKUP_LINE" ]; then
    DATE_STR=$(echo "$LAST_BACKUP_LINE" | awk '{print $1, $2, $3, $4, $5, $6}')
    LAST_EPOCH=$(date -d "$DATE_STR" +%s 2>/dev/null)
    NOW_EPOCH=$(date +%s)
    if [ -n "$LAST_EPOCH" ]; then
        DIFF=$(( (NOW_EPOCH - LAST_EPOCH) / 86400 ))
        if [ "$DIFF" -gt 8 ]; then
            alert_once "backup_overdue" "📅 WARNING: Last backup was $DIFF days ago!"
        else
            clear_alert "backup_overdue"
        fi
    fi
fi

FAILED=$(journalctl -u ssh --since "5 minutes ago" 2>/dev/null | grep -c "Failed password")
if [ "$FAILED" -gt 0 ]; then
    send_message "🚨 SECURITY: $FAILED failed SSH login attempt(s) in last 5 minutes!"
fi

CURRENT_DEVICES=$(tailscale status 2>/dev/null | grep -v "^#" | awk '{print $1}' | sort | md5sum)
STORED_DEVICES=$(cat $STATE_DIR/tailscale_devices 2>/dev/null)
if [ -n "$STORED_DEVICES" ] && [ "$CURRENT_DEVICES" != "$STORED_DEVICES" ]; then
    send_message "🌐 ALERT: Change detected in Tailscale network devices!"
fi
echo "$CURRENT_DEVICES" > $STATE_DIR/tailscale_devices

UPTIME_SECS=$(cat /proc/uptime | awk '{print $1}' | cut -d. -f1)
ONLINE_FLAG="$STATE_DIR/online_notified"
BOOT_FLAG=$(stat -c %Y /proc/1 2>/dev/null)
if [ "$UPTIME_SECS" -lt 360 ]; then
    if [ ! -f "$ONLINE_FLAG" ] || [ "$BOOT_FLAG" -gt "$(cat $ONLINE_FLAG 2>/dev/null || echo 0)" ]; then
        send_message "💤 Pi just came back online! Uptime: ${UPTIME_SECS} seconds."
        echo "$BOOT_FLAG" > "$ONLINE_FLAG"
    fi
fi
