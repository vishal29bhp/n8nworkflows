# Cricket Tournament WhatsApp Help Desk (n8n)

A parent sends a WhatsApp message like *"When is Aarav playing next?"* or *"Where is the final?"* to the academy's WhatsApp number. n8n reads the tournament sheet, Claude writes a short answer using only that data, and the reply goes back to **that parent's number only**.

```
WhatsApp Trigger → Is Text Message? → Extract Question → Read Fixtures → Read Squads → Build AI Prompt → Ask Claude → Reply on WhatsApp
```

## Files
| File | What it is |
|---|---|
| `cricket-whatsapp-helpdesk.json` | Import this into n8n (Workflows → Import from File) |
| `tournament-fixtures-template.xlsx` | Sample data with the exact column names the workflow expects |

## Important: groups vs direct messages
The official WhatsApp Business Cloud API (what n8n uses) **cannot read messages inside a normal WhatsApp group**. The working setup is:
1. Get a dedicated academy WhatsApp Business number (it must not be in use on the regular WhatsApp app).
2. Post one message in the parents' group: *"For fixtures, timings, venues and squads, message this number: +91 XXXXX XXXXX. You'll get an instant reply."*
3. Parents message that number directly, and each one gets a private answer.

Unofficial tools that scrape group chats exist, but they break WhatsApp's terms and the number can get banned, so they're not used here.

## Setup (about 30–45 minutes)

### 1. Put the data in Google Sheets
1. Upload `tournament-fixtures-template.xlsx` (or your real file) to Google Drive and open it with Google Sheets (File → Save as Google Sheets).
2. Keep two tabs with these exact headers:
   - **Fixtures**: `Match No | Date | Time | Venue | Team A | Team B | Stage`
   - **Squads**: `Team | Players` (players comma-separated in one cell)
3. Copy the sheet ID from the URL: `docs.google.com/spreadsheets/d/<THIS_PART>/edit`.

If your real xls has different column names, either rename the headers or edit the names in the **Build AI Prompt** Code node.

### 2. WhatsApp Business Cloud API (Meta, free tier)
1. Go to developers.facebook.com → Create App → **Business** → add the **WhatsApp** product.
2. Under WhatsApp → API Setup, add and verify the academy's phone number. Note the **Phone number ID**.
3. Create a **permanent access token** (Business Settings → System Users → Generate token with `whatsapp_business_messaging` and `whatsapp_business_management`).
4. In n8n create two credentials:
   - **WhatsApp API** (used for sending): Access Token + Business Account ID.
   - **WhatsApp OAuth API** (used by the trigger): App ID + App Secret.
5. Activate the workflow. n8n registers the webhook with Meta automatically. Your n8n must be reachable over public HTTPS (n8n Cloud works as is; self-hosted needs a domain or a tunnel).

Replying to a message a parent sent is free within 24 hours of their message, so normal Q&A has no template or approval overhead.

### 3. Claude API key
1. Get a key at console.anthropic.com.
2. In n8n create a **Header Auth** credential named `Anthropic API Key`: Name `x-api-key`, Value = your key.

The workflow uses `claude-haiku-5-5`, which is fast and cheap (a whole tournament's worth of questions costs pennies). Change `model` in the Build AI Prompt node if you prefer another model.

### 4. Fill in the placeholders
- **Read Fixtures** and **Read Squads**: replace `PASTE_YOUR_GOOGLE_SHEET_ID`.
- **Reply on WhatsApp**: replace `PASTE_YOUR_WHATSAPP_PHONE_NUMBER_ID`.
- Pick the matching credential on each node (open the node and choose it from the dropdown).

## Test it
1. In Meta's API Setup page, add your own mobile as a test recipient.
2. Activate the workflow, then send from your phone:
   - "When does Royal Strikers play?"
   - "Which team is Aarav A1 in and when is his next match?"
   - "Where is the final?"
   - "Is there a match on 3 Nov?"
   - "What's the prize money?" → should say it doesn't have that info.
3. Check **Executions** in n8n if no reply arrives.

## How it behaves
- Answers only from the sheet and never invents timings or venues.
- Finds a child's team from the Squads tab when a parent asks by player name.
- Edits to the sheet (rain delay, venue change, semi-final teams filled in) take effect on the very next question with no redeploy.
- Images, voice notes and delivery receipts are ignored by the "Is Text Message?" filter.
- If Claude is unreachable, it retries once and then sends a polite "please try again or contact the office" message, so a parent is never left without a reply.

## Easy extensions
- **Broadcast changes**: add a Google Sheets Trigger on the Fixtures tab so that when a row changes, n8n messages all registered parents (requires an approved WhatsApp template).
- **Log questions**: append each question/answer to a "Log" tab to see what parents ask most.
- **Hindi or other languages**: add "Reply in the same language the parent uses" to the system prompt rules.
- **Results and points table**: add a Results tab and include it in the prompt so parents can ask for scores and standings.
