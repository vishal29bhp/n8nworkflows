# Windows version of test-mock.sh. Sends the sample payment screenshots to the MOCK workflow as fake
# WhatsApp image messages and prints the confirmation the customer would get plus the row written to the sheet.
# Works in Windows PowerShell 5.1 (built into Windows 10/11) and PowerShell 7.
#
# Usage (run from the whatsapp-payment-reader folder, or give the full path to this script):
#   powershell -ExecutionPolicy Bypass -File .\test-mock.ps1                                     # all samples, default URL
#   powershell -ExecutionPolicy Bypass -File .\test-mock.ps1 -Image C:\path\to\screenshot.png -Caption "note"
#   powershell -ExecutionPolicy Bypass -File .\test-mock.ps1 <webhook-url> [screenshot] [caption]
#
# Webhook URL (from the "Mock WhatsApp Webhook" node):
#   production URL: https://qcai.app.n8n.cloud/webhook/whatsapp-payment-mock       (default; workflow must be Active/Published)
#   test URL:       https://qcai.app.n8n.cloud/webhook-test/whatsapp-payment-mock  (click "Listen for test event" first, one message per click)
#   local n8n:      http://localhost:5678/webhook/whatsapp-payment-mock
param(
  [string]$Url = 'https://qcai.app.n8n.cloud/webhook/whatsapp-payment-mock',
  [string]$Image = '',
  [string]$Caption = ''
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Send-Message([string]$Phone, [string]$Name, [string]$Text, [string]$File = '') {
  $msg = @{ from = $Phone; id = "wamid.MOCK$(Get-Random)"; timestamp = "$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())" }
  if ($File) {
    $bytes = [IO.File]::ReadAllBytes((Resolve-Path $File))
    # Set the type from the file's first bytes, not its name: a ".png" is often really a JPEG
    $sig = ($bytes[0..3] | ForEach-Object { $_.ToString('X2') }) -join ''
    $mime = 'image/jpeg'
    if ($sig.StartsWith('89504E47')) { $mime = 'image/png' }
    elseif ($sig.StartsWith('47494638')) { $mime = 'image/gif' }
    elseif ($sig.StartsWith('52494646')) { $mime = 'image/webp' }
    $msg.type = 'image'
    $msg.image = @{ id = "MOCK_MEDIA_$(Get-Random)"; mime_type = $mime; sha256 = 'mock'; caption = $Text
                    mock_base64 = [Convert]::ToBase64String($bytes) }
  } else {
    $msg.type = 'text'
    $msg.text = @{ body = $Text }
  }
  $payload = @{
    object = 'whatsapp_business_account'
    entry = @(@{ id = 'MOCK_WABA_ID'; changes = @(@{ field = 'messages'; value = @{
      messaging_product = 'whatsapp'
      metadata = @{ display_phone_number = '910000000000'; phone_number_id = 'MOCK_PHONE_ID' }
      contacts = @(@{ profile = @{ name = $Name }; wa_id = $Phone })
      messages = @($msg)
    } }) })
  }
  $body = [System.Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json -Depth 10 -Compress))

  Write-Host '------------------------------------------'
  $what = ''
  if ($File) { $what = " [$(Split-Path $File -Leaf)]" }
  if ($Text) { $what += " `"$Text`"" }
  Write-Host "$Name (+$Phone):$what" -ForegroundColor Cyan
  try {
    $resp = Invoke-RestMethod -Method Post -Uri $Url -ContentType 'application/json; charset=utf-8' -Body $body
  } catch {
    Write-Host "Request failed: $($_.Exception.Message)" -ForegroundColor Red
    return
  }
  if ($resp -is [string]) { try { $resp = $resp | ConvertFrom-Json } catch {} }
  if ($resp.text) {
    Write-Host "reply to +$($resp.to): $($resp.text.body)" -ForegroundColor Green
  } else {
    Write-Host ($resp | ConvertTo-Json -Depth 5)
  }
  if ($resp.logged_row) {
    $cells = $resp.logged_row.PSObject.Properties | ForEach-Object { "$($_.Name)=$($_.Value)" }
    Write-Host "row: $($cells -join ' | ')" -ForegroundColor DarkGray
  }
}

if ($Image) {
  Send-Message '919800000001' 'Test Customer' $Caption $Image
  exit 0
}

$S = Join-Path $PSScriptRoot 'samples'
Send-Message '919812300001' 'Rahul'  'Aarav October fees'  (Join-Path $S '01-gpay-success.png')
Send-Message '919876501234' 'Priya'  ''                    (Join-Path $S '02-phonepe-success.png')
Send-Message '919812300003' 'Vikram' 'For Ishaan, thanks'  (Join-Path $S '03-whatsapp-pay.png')
Send-Message '919820011223' 'Anjali' 'Riya - Nov coaching' (Join-Path $S '04-cred-success.png')
Send-Message '919004055678' 'Sameer' 'Paid, please check'  (Join-Path $S '05-bhim-pending.png')
Send-Message '919812300006' 'Neha'   ''                    (Join-Path $S '06-not-a-payment.png')
Send-Message '919812300001' 'Rahul'  'Sending again'       (Join-Path $S '01-gpay-success.png')   # duplicate -> flagged
Send-Message '919812300007' 'Karan'  'Hi, I have paid the fees'                       # text only -> asks for screenshot
