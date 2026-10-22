# WhatsApp Payment Screenshot Reader (n8n)

A customer pays by UPI and sends the "payment successful" screenshot to the business WhatsApp number, often with a caption like *"Aarav October fees"*. n8n picks it up, Claude reads the screenshot, and a row lands in the **Payments** spreadsheet in Google Drive with the mobile number, amount, transaction ID, date and comments. The customer gets a confirmation back on WhatsApp.

Works with screenshots from Google Pay, PhonePe, Paytm, WhatsApp Pay, CRED, BHIM, Amazon Pay and bank apps. There is no per-app template: Claude reads whatever layout it is given.

```
WhatsApp image message → Has Screenshot? → Download image → Claude reads it → Parse Payment Details
  → Is Payment? → Check Duplicate (same Txn ID already logged?) → Append to Payments sheet → Reply to the customer
```

## Files
| File | What it is |
|---|---|
| `whatsapp-payment-reader-mock.json` | **Demo version.** WhatsApp is mocked, so it runs without a WhatsApp API subscription |
| `whatsapp-payment-reader.json` | Real version for when you have the WhatsApp Business Cloud API |
| `payments-sheet-template.xlsx` | The Payments sheet with all headers. Upload to Google Drive and open as a Google Sheet |
| `samples/` | 6 fake payment screenshots for the demo (watermarked "DEMO SAMPLE") and the script that made them |
| `test-mock.sh` | Sends the sample screenshots to the mock workflow and prints the reply and the logged row |
| [`../prompts/payment-screenshot-extraction.md`](../prompts/payment-screenshot-extraction.md) | The RCTFC extraction prompt Claude uses |

## The spreadsheet
One tab named **Payments**, one row per screenshot:

| Column | Filled from |
|---|---|
| Received At | When the WhatsApp message arrived (IST) |
| Sender WhatsApp | The number that sent the screenshot |
| Sender Name | The sender's WhatsApp profile name |
| **Mobile Number** | The payer's mobile if the screenshot shows it, otherwise the sender's WhatsApp number |
| Payer Name | From the screenshot (From / Debited from / Paid by) |
| **Amount** | From the screenshot, in rupees |
| **Txn ID** | The 12-digit UPI reference (UPI transaction ID / UPI Ref No / UTR). If there is none, the app's own ID |
| **Payment Date**, Payment Time | From the screenshot, as `YYYY-MM-DD` and 24-hour `HH:mm` |
| Payment App | Google Pay, PhonePe, CRED, … |
| Payment Status | Success, Pending, Failed or Unknown |
| Paid To | Payee name and UPI ID, so you can spot payments made to someone else |
| **Comments** | The note written in the screenshot, the WhatsApp caption, and any extra reference number |
| Review Status | `OK`, `Needs review: <why>` or `Duplicate of payment logged at <time>` |
| Confidence | high / medium / low, from Claude |
| WhatsApp Message ID | To trace the row back to the message |

Sort or filter on **Review Status** to see only what a person needs to check. The Google Sheet can be downloaded as `.xlsx` any time (File → Download → Microsoft Excel).

## How it behaves
| Customer sends | Sheet | Reply |
|---|---|---|
| A clear successful payment | New row, `OK` | ✅ Received ₹1,500 on 22 Oct 2026 (Txn ID 629514873201) via Google Pay. Thank you! |
| A pending or failed payment, a blurry or cropped image, or a screenshot missing the amount or Txn ID | New row, `Needs review: …` | Thanks, we got your screenshot for ₹800 … Our team will verify it and confirm shortly. |
| The same screenshot again | New row, `Duplicate of …` | This payment … is already recorded. No need to send it again. |
| An image that isn't a payment | Nothing logged | Sorry, this doesn't look like a payment screenshot … |
| Text only ("I have paid") | Nothing logged | Please send the payment screenshot as an image … |
| Anything while Claude is unreachable | New row, `Needs review: could not read …` (retried once first) | Our team will verify it … |

Nothing a customer sends is lost: if a screenshot can't be read automatically it is still logged for a person to check.

Optional: to flag payments made to the wrong account, set `EXPECTED_PAYEE` at the top of the **Parse Payment Details** node, e.g. `['sunrise']`. Any screenshot whose payee name or UPI ID doesn't contain one of those words is marked `Needs review: paid to someone else`.

## Demo without WhatsApp (mock mode)
The mock workflow is the real workflow with only the WhatsApp nodes swapped:

| Real workflow | Mock workflow |
|---|---|
| WhatsApp Trigger + Get Media URL + Download Screenshot | **Mock WhatsApp Webhook**: accepts the same JSON Meta sends for an image message. Because there's no Meta server to download from, the image travels inside the message as `image.mock_base64` |
| Reply on WhatsApp | **Mock WhatsApp Reply**: returns the message that *would* be sent, plus the row written to the sheet |

Claude, the parsing, the duplicate check and the Google Sheet are all real.

1. Do setup steps 1, 2 and 4 below (sheet and Claude key). Skip step 3.
2. Import `whatsapp-payment-reader-mock.json` (Workflows → Import from File), set the sheet ID in **Read Logged Payments** and **Append to Payments Sheet**, pick your credentials, and activate it.
3. Open the Payments sheet next to the terminal and run:
   ```bash
   ./test-mock.sh http://localhost:5678/webhook/whatsapp-payment-mock
   ```
   It sends the 6 sample screenshots, then resends the first one and sends a text-only message. Rows appear in the sheet one by one.
4. Try your own screenshot (JPG or PNG):
   ```bash
   ./test-mock.sh http://localhost:5678/webhook/whatsapp-payment-mock ~/Downloads/my-payment.jpg "Rent for November"
   ```
5. No terminal? In Postman, POST the JSON from `test-mock.sh` to the same URL.

**Suggested stakeholder walkthrough (5 minutes):** show the sample screenshots side by side with the empty sheet → run the script → point out that each app's different layout ends up in the same columns → the pending payment flagged for review → the resend marked as duplicate → the tournament notice rejected → open one execution in n8n to show what Claude returned.

### Sample screenshots
| File | Shows | Expected result |
|---|---|---|
| `01-gpay-success.png` | Google Pay-style, ₹1,500, no payer mobile | OK, Mobile Number = sender's WhatsApp |
| `02-phonepe-success.png` | PhonePe-style, ₹2,500, payer mobile, Txn ID and UTR | OK, UTR as Txn ID, PhonePe ID in Comments |
| `03-whatsapp-pay.png` | WhatsApp Pay chat bubble, ₹3,000, dated 21/10/2026 | OK, date read day-first |
| `04-cred-success.png` | CRED-style dark theme, ₹1,200 | OK |
| `05-bhim-pending.png` | BHIM-style, ₹800, **Pending** | Needs review: payment pending |
| `06-not-a-payment.png` | A tournament notice | Rejected, not logged |

All names, numbers and IDs are made up, and every image is watermarked. To change them, edit and run `samples/generate_samples.py` (needs `pip install pillow`).

## Setup

### 1. Create the Payments sheet
1. Upload `payments-sheet-template.xlsx` to Google Drive, open it, and choose File → Save as Google Sheets.
2. Keep the tab name `Payments` and the headers as they are.
3. Copy the sheet ID from the URL: `docs.google.com/spreadsheets/d/<THIS_PART>/edit`, and paste it into **Read Logged Payments** and **Append to Payments Sheet**.

### 2. Google Sheets credential
In n8n create a **Google Sheets OAuth2** credential named `Google Sheets account` and pick it on both sheet nodes.

### 3. WhatsApp Business Cloud API (real workflow only)
1. developers.facebook.com → Create App → **Business** → add **WhatsApp**. Add and verify the business number and note the **Phone number ID**.
2. Create a **permanent access token** (Business Settings → System Users → token with `whatsapp_business_messaging` and `whatsapp_business_management`).
3. In n8n create three credentials:
   - **WhatsApp OAuth API** (`WhatsApp OAuth account`, used by the trigger): App ID + App Secret.
   - **WhatsApp API** (`WhatsApp account`, used to reply): access token + Business Account ID.
   - **Header Auth** (`WhatsApp Bearer Token`, used to download the screenshot): Name `Authorization`, Value `Bearer <access token>`.
4. Replace `PASTE_YOUR_WHATSAPP_PHONE_NUMBER_ID` in **Reply on WhatsApp**, **Reply: Ask for Screenshot** and **Reply: Not a Payment**.
5. Activate the workflow. n8n registers the webhook with Meta. n8n must be reachable over public HTTPS.

Replying within 24 hours of the customer's message is free and needs no template approval.

### 4. Claude API key
1. Get a key at console.anthropic.com.
2. In n8n create a **Header Auth** credential named `Anthropic API Key`: Name `x-api-key`, Value = your key.

The workflow uses `claude-sonnet-5-5` for the best accuracy on small print like 12-digit reference numbers. For high volumes, change `MODEL` in **Build Extraction Request** to `claude-haiku-5-5`, which is cheaper and still reads clear screenshots well.

## Going live
Import `whatsapp-payment-reader.json`, do step 3, and point it at the same sheet. Everything after the image download is identical to the mock, so what you demoed is what runs.

## Easy extensions
- **PDF receipts**: bank apps sometimes share a PDF. Claude reads PDFs too; add a `document` content block in **Build Extraction Request** for `application/pdf`.
- **Match against expected fees**: look up the sender's number in a Members tab and flag amounts that don't match what they owe.
- **Daily summary**: a Schedule Trigger that totals today's `OK` rows and messages the owner.
- **Real `.xlsx` file instead of a Google Sheet**: download the file from Drive, add the row, upload it back (slower, and two screenshots arriving together can overwrite each other, which is why a Google Sheet is the default).
