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
| `test-mock.sh` / `test-mock.ps1` | Sends the sample screenshots to the mock workflow and prints the reply and the logged row (`.sh` for Mac/Linux/Git Bash, `.ps1` for Windows PowerShell) |
| [`COSTS.md`](COSTS.md) | Monthly running costs for WhatsApp, Claude and n8n (250 screenshots a month), in ₹ and $ |
| [`../prompts/payment-screenshot-extraction.md`](../prompts/payment-screenshot-extraction.md) | The RCTFC extraction prompt Claude uses |

## Windows step by step: run the demo from VS Code
VS Code is where you keep the files and open terminals. The workflow itself runs inside **n8n**, which you start from a VS Code terminal and use in your browser. Allow about 30 minutes the first time, most of it for the Google sign-in setup in step 4.

### What you need
| | Where to get it |
|---|---|
| Node.js 22 LTS (includes `npx`) | nodejs.org → download the Windows LTS installer → install with the defaults. Close and reopen VS Code afterwards |
| Git and VS Code | You already have these if you can pull the repo |
| A Google account | For the Payments sheet |
| An Anthropic API key | console.anthropic.com → API Keys → Create key. Add a little credit under Billing (the demo costs a few rupees) |

Check Node: in VS Code open **Terminal → New Terminal** and run `node -v`. It should print `v22.x` (v20.19 or later also works).

### 1. Get the files
In VS Code: **Terminal → New Terminal**, then
```powershell
git clone https://github.com/vishal29bhp/n8nworkflows.git
cd n8nworkflows
```
If you already have the repo, run `git pull` in it instead.

### 2. Start n8n
In the same terminal:
```powershell
npx n8n
```
The first run downloads n8n and takes a few minutes. When it prints `Editor is now accessible via: http://localhost:5678`, open that address in your browser and create your owner account. It's local, so any email and password will do.

Leave this terminal running. n8n stops when you close it, and `npx n8n` starts it again with everything you saved.

### 3. Create the Payments sheet
1. Go to drive.google.com → **New → File upload** → choose `whatsapp-payment-reader\payments-sheet-template.xlsx`.
2. Open it, then **File → Save as Google Sheets**. Use the new Google Sheet from now on, not the .xlsx.
3. Copy the sheet ID from the address bar: `docs.google.com/spreadsheets/d/`**`<THIS_PART>`**`/edit`. Keep it in Notepad for step 6.

### 4. Connect n8n to Google Sheets (one-time Google Cloud setup)
On n8n running on your own computer, Google sign-in needs your own OAuth client:
1. Go to console.cloud.google.com → project picker at the top → **New Project** (e.g. `n8n-demo`) → select it.
2. **APIs & Services → Library** → search **Google Sheets API** → **Enable**. Do the same for **Google Drive API**.
3. **APIs & Services → OAuth consent screen** (may be called *Google Auth Platform*) → **Get started** → app name `n8n demo`, your email → Audience **External** → finish. Under **Audience → Test users**, add your own Gmail address.
4. **APIs & Services → Credentials → Create credentials → OAuth client ID** → type **Web application** → under **Authorized redirect URIs** add
   `http://localhost:5678/rest/oauth2-credential/callback` → **Create**. Copy the **Client ID** and **Client secret**.
5. In n8n: left sidebar **Overview → Credentials** tab (or **Create → Credential**) → search **Google Sheets OAuth2 API** → paste the Client ID and Client secret → **Sign in with Google** → choose your account. If Google warns "app isn't verified", click **Continue**, since it's your own app. Save it with the name `Google Sheets account`.

### 5. Add your Claude API key to n8n
**Create → Credential** → search **Header Auth** → Name: `x-api-key`, Value: your Anthropic key → save it with the name `Anthropic API Key`.

### 6. Import the workflow
1. In n8n: **Create → Workflow**. Then use the **⋯** menu at the top right → **Import from File** → pick `whatsapp-payment-reader\whatsapp-payment-reader-mock.json`.
2. Double-click **Read Logged Payments**: in *Document*, paste your sheet ID in place of `PASTE_YOUR_GOOGLE_SHEET_ID`, and pick `Google Sheets account` as the credential. Close it.
3. Do the same in **Append to Payments Sheet**.
4. Double-click **Read Screenshot with Claude** and pick `Anthropic API Key` as the credential.
5. **Save** (Ctrl+S). No node should show a red warning triangle any more.

### 7. Turn it on
Click the **Inactive / Active** toggle at the top (called **Publish** in newer n8n versions). The **Mock WhatsApp Webhook** node now listens at
`http://localhost:5678/webhook/whatsapp-payment-mock`.

### 8. Run the demo
> **Using n8n Cloud (`qcai.app.n8n.cloud`)?** The scripts already point at it, so from the repo folder just run:
> ```powershell
> cd whatsapp-payment-reader
> powershell -ExecutionPolicy Bypass -File .\test-mock.ps1
> powershell -ExecutionPolicy Bypass -File .\test-mock.ps1 -Image .\samples\vishal.png -Caption "Transport and Match Fee"
> ```
> The first sends all the samples, the second one screenshot of your own. The workflow must be **Active/Published** for this URL. To use the *webhook-test* URL instead, click **Execute workflow / Listen for test event** in n8n first and send one message at a time: add `-Url https://qcai.app.n8n.cloud/webhook-test/whatsapp-payment-mock`.
>
> The `cd whatsapp-payment-reader` matters: `.\test-mock.ps1` means "in this folder", so running it from the repo root gives *"The argument '.\test-mock.ps1' ... does not exist"*.

Local n8n: open a **second** terminal in VS Code (the **+** in the terminal panel) and leave n8n running in the first one:
```powershell
cd whatsapp-payment-reader
powershell -ExecutionPolicy Bypass -File .\test-mock.ps1 http://localhost:5678/webhook/whatsapp-payment-mock
```
For each screenshot you'll see who sent it, the WhatsApp reply they would get, and the row that was saved. Keep the Google Sheet open next to it: rows appear one by one. Every run is also recorded in n8n under **Executions**, where you can click any node to see what went in and out, including Claude's raw answer.

To try a real screenshot of your own (JPG or PNG):
```powershell
powershell -ExecutionPolicy Bypass -File .\test-mock.ps1 http://localhost:5678/webhook/whatsapp-payment-mock "C:\Users\<you>\Downloads\payment.jpg" "Rent for November"
```
Running the samples again adds them as *Duplicate* rows, because the Txn IDs are already in the sheet. To start a demo fresh, delete the data rows (keep row 1 with the headers).

### If something goes wrong
| You see | Fix |
|---|---|
| `npx` is not recognized | Node.js isn't installed, or VS Code was open during the install. Reinstall Node and restart VS Code |
| `404` / *webhook is not registered* | The workflow isn't active (step 7), or the URL has a typo |
| Reply says "our team will verify" for every screenshot, and the row says *could not read the screenshot automatically* | Claude call failed. Open the execution → **Read Screenshot with Claude** to see why: usually a wrong key, the credential name isn't `x-api-key`, or no credit on the Anthropic account |
| Google error `403` or *access blocked* | Sheets/Drive API not enabled (step 4.2), or your Gmail isn't a test user (step 4.3) |
| Google error `redirect_uri_mismatch` | The redirect URI in step 4.4 must match exactly what n8n shows in the credential window |
| Sheet error *Sheet with name Payments not found* | The tab must be named `Payments`, and the ID must be from the Google Sheet, not the uploaded .xlsx |
| Port 5678 already in use | n8n is already running in another terminal; use that one |
| *The argument '.\test-mock.ps1' to the -File parameter does not exist* | You're in the wrong folder. Run `cd whatsapp-payment-reader` first, or use the full path: `-File .\whatsapp-payment-reader\test-mock.ps1` |
| Only the first message works with a *webhook-test* URL | Test URLs accept one call per click on *Listen for test event*. Use the production URL (`/webhook/`, workflow Active) for the full run |

### Alternative: n8n Cloud (no install)
Sign up at n8n.io (there's a free trial). Steps 1 and 2 go away, and in step 4 you just click **Sign in with Google** on the Google Sheets credential, with no Google Cloud project. Do steps 3, 5, 6 and 7 the same way. Then run the test script with your cloud address instead of localhost:
```powershell
powershell -ExecutionPolicy Bypass -File .\test-mock.ps1 -Url https://<your-name>.app.n8n.cloud/webhook/whatsapp-payment-mock
```
(For `qcai.app.n8n.cloud` this is already the default, so `-Url` can be left out.)
You need n8n Cloud, or another public HTTPS address, later anyway for real WhatsApp, because Meta can't reach `localhost`.

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

On Windows, follow [Windows step by step](#windows-step-by-step-run-the-demo-from-vs-code) above instead of the short version below.

1. Do setup steps 1, 2 and 4 below (sheet and Claude key). Skip step 3.
2. Import `whatsapp-payment-reader-mock.json` (Workflows → Import from File), set the sheet ID in **Read Logged Payments** and **Append to Payments Sheet**, pick your credentials, and activate it.
3. Open the Payments sheet next to the terminal and run:
   ```bash
   ./test-mock.sh http://localhost:5678/webhook/whatsapp-payment-mock
   ```
   On Windows, open PowerShell in this folder and run:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\test-mock.ps1 http://localhost:5678/webhook/whatsapp-payment-mock
   ```
   It sends the 6 sample screenshots, then resends the first one and sends a text-only message. Rows appear in the sheet one by one.
4. Try your own screenshot (JPG or PNG):
   ```bash
   ./test-mock.sh http://localhost:5678/webhook/whatsapp-payment-mock ~/Downloads/my-payment.jpg "Rent for November"
   ```
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\test-mock.ps1 http://localhost:5678/webhook/whatsapp-payment-mock C:\Users\you\Downloads\my-payment.jpg "Rent for November"
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

Replying within 24 hours of the customer's message needs no template approval. Since 1 Oct 2026 these replies are no longer unlimited and free: each business number gets 1,000 free a month, then ₹0.115 each in India. See [COSTS.md](COSTS.md).

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
