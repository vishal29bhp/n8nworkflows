#!/usr/bin/env bash
# Sends the sample payment screenshots to the MOCK workflow as fake WhatsApp image messages
# and prints the confirmation the customer would get plus the row written to the sheet.
#
# Usage:
#   ./test-mock.sh <webhook-url>                                  # all 6 samples + a resend + a text-only message
#   ./test-mock.sh <webhook-url> path/to/screenshot.jpg ["caption"]  # your own screenshot
#
# Webhook URL (from the "Mock WhatsApp Webhook" node):
#   test URL:       http://localhost:5678/webhook-test/whatsapp-payment-mock  (click "Listen for test event" first, one message per click)
#   production URL: http://localhost:5678/webhook/whatsapp-payment-mock       (workflow must be Active)
set -euo pipefail

URL="${1:-http://localhost:5678/webhook/whatsapp-payment-mock}"
DIR="$(cd "$(dirname "$0")" && pwd)"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

# send <phone> <name> <caption> [image-file]
send() {
  local phone="$1" name="$2" caption="$3" file="${4:-}"
  local msg
  if [ -n "$file" ]; then
    local mime="image/jpeg"
    case "$file" in *.png) mime="image/png" ;; *.webp) mime="image/webp" ;; esac
    msg=$(cat <<JSON
"type": "image",
          "image": {
            "id": "MOCK_MEDIA_$RANDOM",
            "mime_type": "$mime",
            "sha256": "mock",
            "caption": "$caption",
            "mock_base64": "$(base64 < "$file" | tr -d '\n')"
          }
JSON
)
  else
    msg="\"type\": \"text\", \"text\": { \"body\": \"$caption\" }"
  fi
  cat > "$TMP" <<JSON
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
          $msg
        }]
      }
    }]
  }]
}
JSON
  echo "──────────────────────────────────────────"
  echo "📱 $name (+$phone):${file:+ [$(basename "$file")]}${caption:+ \"$caption\"}"
  local resp
  resp=$(curl -sS -X POST "$URL" -H 'Content-Type: application/json' --data-binary @"$TMP")
  if command -v jq >/dev/null 2>&1; then
    echo "🤖 reply to +$(echo "$resp" | jq -r '.to // "?"'): $(echo "$resp" | jq -r '.text.body // .')"
    echo "$resp" | jq -r 'if .logged_row then "📄 row: " + (.logged_row | to_entries | map("\(.key)=\(.value)") | join(" | ")) else empty end'
  else
    echo "🤖 $resp"
  fi
}

if [ $# -ge 2 ]; then
  send "919800000001" "Test Customer" "${3:-}" "$2"
  exit 0
fi

S="$DIR/samples"
send "919812300001" "Rahul"   "Aarav October fees"   "$S/01-gpay-success.png"
send "919876501234" "Priya"   ""                     "$S/02-phonepe-success.png"
send "919812300003" "Vikram"  "For Ishaan, thanks"   "$S/03-whatsapp-pay.png"
send "919820011223" "Anjali"  "Riya - Nov coaching"  "$S/04-cred-success.png"
send "919004055678" "Sameer"  "Paid, please check"   "$S/05-bhim-pending.png"
send "919812300006" "Neha"    ""                     "$S/06-not-a-payment.png"
send "919812300001" "Rahul"   "Sending again"        "$S/01-gpay-success.png"   # duplicate → flagged
send "919812300007" "Karan"   "Hi, I have paid the fees"                        # text only → asks for screenshot
