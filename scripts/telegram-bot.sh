#!/bin/bash
TELEGRAM_TOKEN="YOUR_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"
OFFSET_FILE="/var/lib/pimonitor/offset"
mkdir -p /var/lib/pimonitor

send_message() {
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
    -d chat_id="${CHAT_ID}" \
    -d text="$1" > /dev/null
}

get_status() {
    df -h /mnt/nas-hdd /mnt/media-ssd /mnt/storage | awk 'NR==1{next} {printf "%s Used: %s / %s (%s free)\n", $6, $3, $2, $4}'
}

get_health() {
    MSG="Drive Health:"$'\n'
    for dev in sda sdb sdc; do
        HEALTH=$(smartctl -H /dev/$dev 2>/dev/null | grep "overall-health" | awk '{print $NF}')
        TEMP=$(smartctl -A /dev/$dev 2>/dev/null | grep -i "Temperature_Celsius" | awk '{print $10}')
        if [ -n "$HEALTH" ]; then
            MSG+="/dev/$dev: $HEALTH"
            [ -n "$TEMP" ] && MSG+=" | ${TEMP}C"
            MSG+=$'\n'
        fi
    done
    echo "$MSG"
}

get_temp() {
    CPU=$(vcgencmd measure_temp | cut -d= -f2)
    MSG="Temperatures:"$'\n'
    MSG+="CPU: $CPU"$'\n'
    for dev in sda sdb sdc; do
        TEMP=$(smartctl -A /dev/$dev 2>/dev/null | grep -i "Temperature_Celsius" | awk '{print $10}')
        [ -n "$TEMP" ] && MSG+="/dev/$dev: ${TEMP}C"$'\n'
    done
    echo "$MSG"
}

get_uptime() {
    UP=$(uptime -p)
    LOAD=$(uptime | awk -F'load average:' '{print $2}')
    echo "Uptime: $UP"$'\n'"Load:$LOAD"
}

get_ram() {
    TOTAL=$(free -h | awk 'NR==2{print $2}')
    USED=$(free -h | awk 'NR==2{print $3}')
    FREE=$(free -h | awk 'NR==2{print $4}')
    AVAILABLE=$(free -h | awk 'NR==2{print $7}')
    echo "RAM Status:"$'\n'"Total: $TOTAL"$'\n'"Used: $USED"$'\n'"Free: $FREE"$'\n'"Available: $AVAILABLE"
}

get_speedtest() {
    send_message "Running speedtest, please wait..."
    RESULT=$(/usr/local/bin/speedtest --accept-license --accept-gdpr 2>&1 | grep -E "Download|Upload|Latency|Packet Loss|ISP|Server")
    if [ -n "$RESULT" ]; then
        echo "Speedtest Results:"$'\n'"$RESULT"
    else
        echo "Speedtest failed — try again"
    fi
}

get_containers() {
    RESULT=$(docker ps --format "{{.Names}}: {{.Status}}" 2>/dev/null)
    echo "Docker Containers:"$'\n'"$RESULT"
}

get_logs() {
    RESULT=$(tail -10 /var/log/nas-backup.log 2>/dev/null)
    echo "Last Backup Log:"$'\n'"$RESULT"
}

get_ip() {
    LOCAL=$(hostname -I | awk '{print $1}')
    TAILSCALE=$(tailscale ip 2>/dev/null | head -1)
    echo "IP Addresses:"$'\n'"Local: $LOCAL"$'\n'"Tailscale: $TAILSCALE"
}

get_piinfo() {
    MODEL=$(cat /proc/device-tree/model 2>/dev/null | tr -d '\0')
    OS=$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
    KERNEL=$(uname -r)
    UPTIME=$(uptime -p)
    CPU=$(vcgencmd measure_temp | cut -d= -f2)
    echo "Pi Info:"$'\n'"Model: $MODEL"$'\n'"OS: $OS"$'\n'"Kernel: $KERNEL"$'\n'"Uptime: $UPTIME"$'\n'"CPU Temp: $CPU"
}

get_quote() {
    QUOTES=(
        "The only way to do great work is to love what you do. — Steve Jobs"
        "It does not matter how slowly you go as long as you do not stop. — Confucius"
        "Success is not final, failure is not fatal: it is the courage to continue that counts. — Winston Churchill"
        "Believe you can and you're halfway there. — Theodore Roosevelt"
        "The future belongs to those who believe in the beauty of their dreams. — Eleanor Roosevelt"
        "Hard work beats talent when talent doesn't work hard. — Tim Notke"
        "The secret of getting ahead is getting started. — Mark Twain"
        "In the middle of every difficulty lies opportunity. — Albert Einstein"
        "It always seems impossible until it's done. — Nelson Mandela"
        "You miss 100% of the shots you don't take. — Wayne Gretzky"
        "Education is the most powerful weapon which you can use to change the world. — Nelson Mandela"
        "An investment in knowledge pays the best interest. — Benjamin Franklin"
        "Live as if you were to die tomorrow. Learn as if you were to live forever. — Mahatma Gandhi"
        "Learning never exhausts the mind. — Leonardo da Vinci"
        "The best way to predict the future is to create it. — Peter Drucker"
        "Engineering is the closest thing to magic that exists in the world. — Elon Musk"
        "I have not failed. I've just found 10,000 ways that won't work. — Thomas Edison"
        "Done is better than perfect. — Sheryl Sandberg"
        "Dream big. Start small. Act now. — Robin Sharma"
        "You don't have to be great to start, but you have to start to be great. — Zig Ziglar"
    )
    RANDOM_INDEX=$((RANDOM % ${#QUOTES[@]}))
    echo "💭 ${QUOTES[$RANDOM_INDEX]}"
}

get_news() {
    NEWS_API="YOUR_NEWS_API_KEY"
    F1=$(curl -s --max-time 10 "https://newsapi.org/v2/everything?q=Formula+1+F1&sortBy=publishedAt&pageSize=2&apiKey=$NEWS_API" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    articles = data.get('articles', [])
    for a in articles[:2]:
        print('• ' + a['title'])
except:
    print('Could not fetch F1 news')
" 2>/dev/null)

    AERO=$(curl -s --max-time 10 "https://newsapi.org/v2/everything?q=aerospace+space+aviation&sortBy=publishedAt&pageSize=2&apiKey=$NEWS_API" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    articles = data.get('articles', [])
    for a in articles[:2]:
        print('• ' + a['title'])
except:
    print('Could not fetch aerospace news')
" 2>/dev/null)

    GENERAL=$(curl -s --max-time 10 "https://newsapi.org/v2/top-headlines?country=us&pageSize=3&apiKey=$NEWS_API" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    articles = data.get('articles', [])
    for a in articles[:3]:
        print('• ' + a['title'])
except:
    print('Could not fetch general news')
" 2>/dev/null)

    echo "📰 Latest News:"$'\n\n'"🏎️ F1:"$'\n'"$F1"$'\n\n'"🚀 Aerospace:"$'\n'"$AERO"$'\n\n'"🌍 General:"$'\n'"$GENERAL"
}

get_commands() {
    echo "📋 Available Commands:"$'\n\n'"🔧 System:"$'\n'"• /ping — Check if Pi is alive"$'\n'"• /temp — CPU + drive temperatures"$'\n'"• /uptime — Uptime and load average"$'\n'"• /ram — RAM usage"$'\n'"• /piinfo — Pi model and OS info"$'\n'"• /ip — Local and Tailscale IP"$'\n\n'"💾 Storage:"$'\n'"• /status — Drive capacity and usage"$'\n'"• /health — SMART health for all drives"$'\n'"• /logs — Last 10 lines of backup log"$'\n\n'"🐳 Services:"$'\n'"• /containers — Docker container status"$'\n\n'"🌐 Network:"$'\n'"• /speedtest — Internet speed test"$'\n\n'"⚙️ Actions:"$'\n'"• /backup — Trigger manual backup"$'\n'"• /restart — Reboot Pi (15 sec delay)"$'\n'"• /shutdown — Shutdown Pi (15 sec delay)"$'\n'"• /cancelrestart — Cancel pending restart"$'\n'"• /cancelshutdown — Cancel pending shutdown"$'\n\n'"🎲 Fun:"$'\n'"• /quote — Random motivational quote"$'\n'"• /news — Latest F1, Aerospace and General news"$'\n\n'"🤖 Automatic Alerts:"$'\n'"• 💤 Pi came back online"$'\n'"• 🌡️ Drive temp above 55°C"$'\n'"• 🔥 CPU above 75°C"$'\n'"• 📊 High CPU load"$'\n'"• 💾 Drive above 80% full"$'\n'"• ❌ Drive not mounted"$'\n'"• ❌ Jellyfin down"$'\n'"• 📅 Backup overdue"$'\n'"• 🚨 Failed SSH attempts"$'\n'"• 🌐 New Tailscale device"$'\n'"• ✅ Weekly backup Friday 4am"
}

do_backup() {
    send_message "🔄 Manual backup started..."
    /usr/local/bin/backup-nas.sh &
}

do_restart() {
    send_message "🔄 Restarting Pi in 15 seconds... Send /cancelrestart to abort."
    echo "$OFFSET" > "$OFFSET_FILE"
    for i in $(seq 15 -1 1); do
        if [ -f "/var/lib/pimonitor/cancel_restart" ]; then
            rm -f "/var/lib/pimonitor/cancel_restart"
            send_message "✅ Restart cancelled!"
            return
        fi
        sleep 1
    done
    sudo reboot
}

do_shutdown() {
    send_message "⛔ Shutting down Pi in 15 seconds... Send /cancelshutdown to abort."
    echo "$OFFSET" > "$OFFSET_FILE"
    for i in $(seq 15 -1 1); do
        if [ -f "/var/lib/pimonitor/cancel_shutdown" ]; then
            rm -f "/var/lib/pimonitor/cancel_shutdown"
            send_message "✅ Shutdown cancelled!"
            return
        fi
        sleep 1
    done
    sudo poweroff
}

if [ -f "$OFFSET_FILE" ]; then
    OFFSET=$(cat "$OFFSET_FILE")
else
    RESPONSE=$(curl -s "https://api.telegram.org/bot${TELEGRAM_TOKEN}/getUpdates?limit=1&offset=-1")
    LAST_ID=$(echo $RESPONSE | python3 -c "
import sys, json
data = json.load(sys.stdin)
results = data.get('result', [])
if results:
    print(results[-1]['update_id'] + 1)
else:
    print(0)
")
    OFFSET=${LAST_ID:-0}
    echo "$OFFSET" > "$OFFSET_FILE"
fi

while true; do
    RESPONSE=$(curl -s "https://api.telegram.org/bot${TELEGRAM_TOKEN}/getUpdates?offset=$OFFSET&timeout=60")
    UPDATES=$(echo $RESPONSE | python3 -c "
import sys, json
data = json.load(sys.stdin)
for u in data.get('result', []):
    print(u['update_id'], u.get('message', {}).get('text', ''))
")
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        UPDATE_ID=$(echo $line | awk '{print $1}')
        TEXT=$(echo $line | awk '{$1=""; print $0}' | xargs)
        OFFSET=$((UPDATE_ID + 1))
        echo "$OFFSET" > "$OFFSET_FILE"
        case "$TEXT" in
            "/status")        send_message "$(get_status)" ;;
            "/health")        send_message "$(get_health)" ;;
            "/temp")          send_message "$(get_temp)" ;;
            "/uptime")        send_message "$(get_uptime)" ;;
            "/ping")          send_message "🟢 Pi is alive and running!" ;;
            "/ram")           send_message "$(get_ram)" ;;
            "/speedtest")     send_message "$(get_speedtest)" ;;
            "/containers")    send_message "$(get_containers)" ;;
            "/logs")          send_message "$(get_logs)" ;;
            "/ip")            send_message "$(get_ip)" ;;
            "/piinfo")        send_message "$(get_piinfo)" ;;
            "/quote")         send_message "$(get_quote)" ;;
            "/news")          send_message "$(get_news)" ;;
            "/commands")      send_message "$(get_commands)" ;;
            "/backup")        do_backup ;;
            "/restart")       do_restart ;;
            "/shutdown")      do_shutdown ;;
            "/cancelrestart") touch "/var/lib/pimonitor/cancel_restart" ;;
            "/cancelshutdown") touch "/var/lib/pimonitor/cancel_shutdown" ;;
            *)                [ -n "$TEXT" ] && send_message "❌ Unknown command: $TEXT — Send /commands to see all available commands." ;;
        esac
    done <<< "$UPDATES"
    sleep 1
done
