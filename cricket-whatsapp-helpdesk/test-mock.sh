#!/usr/bin/env bash
# Sends fake WhatsApp messages from parents to the MOCK workflow and prints the bot's replies.
#
# Usage:
#   ./test-mock.sh <webhook-url> ["your own question"]
#
# Webhook URL (from the "Mock WhatsApp Webhook" node):
#   test URL:       http://localhost:5678/webhook-test/whatsapp-mock  (click "Listen for test event" first, one message per click)
#   production URL: http://localhost:5678/webhook/whatsapp-mock       (workflow must be Active)
set -euo pipefail

URL="${1:-http://localhost:5678/webhook/whatsapp-mock}"

send() {
  local phone="$1" name="$2" text="$3"
  local payload
  payload=$(cat <<JSON
{
  "object": "whatsapp_business_account",
  "entry": [{
    "id": "MOCK_WABA_ID",
    "changes": [{
      "field": "messages",
      "value": {
        "messaging_product": "whatsapp",
        "metadata": { "display_phone_number": "910000000000", "phone_number_id": "MOCK_PHONE_ID" },
        "contacts": [{ "profile": { "name": "$name" }, "wa_id": "$phone" }],
        "messages": [{
          "from": "$phone",
          "id": "wamid.MOCK$RANDOM",
          "timestamp": "$(date +%s)",
          "type": "text",
          "text": { "body": "$text" }
        }]
      }
    }]
  }]
}
JSON
)
  echo "──────────────────────────────────────────"
  echo "📱 $name (+$phone): $text"
  local resp
  resp=$(curl -sS -X POST "$URL" -H 'Content-Type: application/json' -d "$payload")
  if command -v jq >/dev/null 2>&1; then
    echo "🤖 reply to +$(echo "$resp" | jq -r '.to // "?"'):"
    echo "$resp" | jq -r '.text.body // .'
  else
    echo "🤖 $resp"
  fi
}

if [ $# -ge 2 ]; then
  send "919800000001" "Test Parent" "$2"
  exit 0
fi

# A few questions from each phase (see sample-questions.md for the full list).
# Run the Tournament Simulator up to 19 Oct (or import tournament-demo-data.xlsx) so results exist.
send "919800000001" "Priya"  "When and where is Thunder Kings' next match?"
send "919800000002" "Rahul"  "Which team is Kabir A6 in and how many runs has he scored so far?"
send "919800000003" "Sneha"  "Show me the points table."
send "919800000004" "Imran"  "Who won yesterday's matches?"
send "919800000005" "Kavita" "Who is the top run scorer and who has the most wickets?"
send "919800000006" "Arjun"  "Who was Player of the Match in match 2?"
send "919800000007" "Meera"  "How do teams qualify for the semi-finals?"
send "919800000008" "Sanjay" "What is the prize money?"
