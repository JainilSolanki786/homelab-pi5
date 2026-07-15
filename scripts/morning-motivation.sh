#!/bin/bash
TELEGRAM_TOKEN="YOUR_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"

send_message() {
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
    -d chat_id="${CHAT_ID}" \
    -d text="$1" > /dev/null
}

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
QUOTE="${QUOTES[$RANDOM_INDEX]}"
send_message "🌅 Good Morning! Rise and shine!"$'\n\n'"💭 $QUOTE"$'\n\n'"Have a productive day! 🚀"
