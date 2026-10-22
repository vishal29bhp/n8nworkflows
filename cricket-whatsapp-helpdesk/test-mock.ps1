# Windows version of test-mock.sh. Sends fake WhatsApp messages from parents to the MOCK workflow and prints the bot's replies.
# Works in Windows PowerShell 5.1 (built into Windows 10/11) and PowerShell 7.
#
# Usage (from this folder):
#   powershell -ExecutionPolicy Bypass -File .\test-mock.ps1 <webhook-url> ["your own question"]
#
# Webhook URL (from the "Mock WhatsApp Webhook" node):
#   test URL:       http://localhost:5678/webhook-test/whatsapp-mock  (click "Listen for test event" first, one message per click)
#   production URL: http://localhost:5678/webhook/whatsapp-mock       (workflow must be Active)
param(
  [string]$Url = 'http://localhost:5678/webhook/whatsapp-mock',
  [string]$Question = ''
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Send-Message([string]$Phone, [string]$Name, [string]$Text) {
  $payload = @{
    object = 'whatsapp_business_account'
    entry = @(@{ id = 'MOCK_WABA_ID'; changes = @(@{ field = 'messages'; value = @{
      messaging_product = 'whatsapp'
      metadata = @{ display_phone_number = '910000000000'; phone_number_id = 'MOCK_PHONE_ID' }
      contacts = @(@{ profile = @{ name = $Name }; wa_id = $Phone })
      messages = @(@{ from = $Phone; id = "wamid.MOCK$(Get-Random)"; timestamp = "$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"
                      type = 'text'; text = @{ body = $Text } })
    } }) })
  }
  $body = [System.Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json -Depth 10 -Compress))

  Write-Host '------------------------------------------'
  Write-Host "$Name (+$Phone): $Text" -ForegroundColor Cyan
  try {
    $resp = Invoke-RestMethod -Method Post -Uri $Url -ContentType 'application/json; charset=utf-8' -Body $body
  } catch {
    Write-Host "Request failed: $($_.Exception.Message)" -ForegroundColor Red
    return
  }
  if ($resp -is [string]) { try { $resp = $resp | ConvertFrom-Json } catch {} }
  if ($resp.text) {
    Write-Host "reply to +$($resp.to):" -ForegroundColor Green
    Write-Host $resp.text.body
  } else {
    Write-Host ($resp | ConvertTo-Json -Depth 5)
  }
}

if ($Question) {
  Send-Message '919800000001' 'Test Parent' $Question
  exit 0
}

# A few questions from each phase (see sample-questions.md for the full list).
# Run the Tournament Simulator up to 19 Oct (or import tournament-demo-data.xlsx) so results exist.
Send-Message '919800000001' 'Priya'  "When and where is Thunder Kings' next match?"
Send-Message '919800000002' 'Rahul'  'Which team is Kabir A6 in and how many runs has he scored so far?'
Send-Message '919800000003' 'Sneha'  'Show me the points table.'
Send-Message '919800000004' 'Imran'  "Who won yesterday's matches?"
Send-Message '919800000005' 'Kavita' 'Who is the top run scorer and who has the most wickets?'
Send-Message '919800000006' 'Arjun'  'Who was Player of the Match in match 2?'
Send-Message '919800000007' 'Meera'  'How do teams qualify for the semi-finals?'
Send-Message '919800000008' 'Sanjay' 'What is the prize money?'
