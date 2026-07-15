#!/bin/bash
TELEGRAM_TOKEN="YOUR_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"
NEWS_API="YOUR_NEWS_API_KEY"

send_message() {
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
    -d chat_id="${CHAT_ID}" \
    -d text="$1" > /dev/null
}

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

send_message "🌅 Good Morning! Daily News:"$'\n\n'"🏎️ F1:"$'\n'"$F1"$'\n\n'"🚀 Aerospace:"$'\n'"$AERO"$'\n\n'"🌍 General:"$'\n'"$GENERAL"
