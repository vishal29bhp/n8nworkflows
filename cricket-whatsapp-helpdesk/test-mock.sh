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

send "919800000001" "Priya"  "When does Royal Strikers play their first match?"
send "919800000002" "Rahul"  "My son Aarav A1 is playing, which team is he in and when is his next game?"
send "919800000003" "Sneha"  "Where and when is the final?"
send "919800000004" "Imran"  "How many overs is each match?"
send "919800000005" "Kavita" "Is there any match on 3 Nov?"
send "919800000006" "Arjun"  "What is the prize money?"
