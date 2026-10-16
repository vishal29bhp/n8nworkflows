# Step-by-step n8n setup guide

This guide takes you from nothing to a working help desk, then walks through every node so you know what goes in, what it does and what comes out.

**Order of work**
1. [Start n8n](#1-start-n8n)
2. [Create the Google Sheet](#2-create-the-google-sheet)
3. [Create the credentials](#3-create-the-credentials-in-n8n)
4. [Set up the Tournament Simulator](#4-workflow-1-tournament-simulator) and play a couple of days
5. [Set up the help desk (mock version)](#5-workflow-2-help-desk-mock-version) and ask it questions
6. [Switch to real WhatsApp](#6-switching-to-real-whatsapp) (later, once you have Meta credentials)
7. [Troubleshooting](#7-troubleshooting)

Both workflows use the **same Google Sheet**. The simulator *writes* scores into it, and the help desk *reads* from it.

```
                 writes                          reads
Simulator  ───────────────▶  Google Sheet  ◀───────────────  Help desk  ◀── parent's question
(nightly / manual)        Fixtures · Squads ·                (webhook or      ──▶ reply to that parent
                          Results · Player Stats              WhatsApp)
```

---

## 1. Start n8n

Use either option.

**n8n Cloud:** sign up at n8n.io, open your workspace, and skip to step 2.

**Self-hosted with Docker (free):**
```bash
docker run -it --rm --name n8n -p 5678:5678 \
  -e GENERIC_TIMEZONE="Asia/Kolkata" -e TZ="Asia/Kolkata" \
  -v n8n_data:/home/node/.n8n \
  docker.n8n.io/n8nio/n8n
```
Then open http://localhost:5678 and create your owner account.

> **Set the timezone.** The simulator's "9 PM" schedule and the help desk's idea of "today" both use n8n's timezone. With the default (UTC), 9 PM would be 2:30 AM in India. On n8n Cloud, set it under **Settings → Personal → Timezone**. On any version you can also set it per workflow under **⋯ → Settings → Timezone**.

---

## 2. Create the Google Sheet

1. Download `tournament-demo-data.xlsx` from this folder. It has days 1 and 2 already played, so it's the best file for a first test. For the real tournament, use `tournament-fixtures-template.xlsx` instead.
2. Upload it to Google Drive, open it, and choose **File → Save as Google Sheets**.
3. Check that it has 4 tabs with these exact names: `Fixtures`, `Squads`, `Results`, `Player Stats`.
4. Copy the **sheet ID** from the address bar:
   ```
   https://docs.google.com/spreadsheets/d/1AbC...xYz/edit#gid=0
                                          └──────┘
                                          this part is the sheet ID
   ```
   You'll paste it into every Google Sheets node.

What's in each tab (row 1 is the header):

| Tab | Example row |
|---|---|
| Fixtures | `1 · 17 Oct 2026 · 08:00 AM · Academy Ground A · A · Royal Strikers · Thunder Kings · League · T20` |
| Squads | `Royal Strikers · A · Aarav A1, Vivaan A2, Aditya A3, … Yash A11` |
| Results | `1 · Royal Strikers · 156 · 5 · 20 · 162 · 4 · 18 · Normal · Thunder Kings · Ayaan B4` |
| Player Stats | `1 · Ishaan A7 · Royal Strikers · 34 · 25 · 3 · 1 · 4 · 29 · 1 · 1` |

Keep the dates in `17 Oct 2026` form. If Google Sheets turns them into real dates, select the Date column and choose **Format → Number → Plain text**, then type them again.

---

## 3. Create the credentials in n8n

Open **Overview → Credentials → Create credential** (or click **+** next to "Credentials" in the left menu).

### 3a. Google Sheets account
1. Search for **Google Sheets OAuth2 API** and select it.
2. **n8n Cloud:** click **Sign in with Google**, pick your account and allow access. You're done.
3. **Self-hosted:** you need your own Google OAuth client (one-time, about 10 minutes):
   1. Go to console.cloud.google.com and create a project (e.g. "n8n").
   2. **APIs & Services → Library**: enable **Google Sheets API** and **Google Drive API**.
   3. **APIs & Services → OAuth consent screen**: choose **External**, fill in the app name and your email, and add your own Gmail under **Test users**.
   4. **APIs & Services → Credentials → Create credentials → OAuth client ID**: choose **Web application**. Under **Authorized redirect URIs**, paste the **OAuth Redirect URL** shown in the n8n credential window (e.g. `http://localhost:5678/rest/oauth2-credential/callback`).
   5. Copy the **Client ID** and **Client Secret** into n8n, click **Sign in with Google**, and allow access.
4. Name the credential **Google Sheets account** and save.

### 3b. Anthropic API key (for Claude)
1. Get a key at console.anthropic.com → **API Keys → Create key**.
2. In n8n, create a credential of type **Header Auth**:
   | Field | Value |
   |---|---|
   | Name | `x-api-key` |
   | Value | your key (starts with `sk-ant-`) |
3. Name the credential **Anthropic API Key** and save.

### 3c. WhatsApp (skip for now)
Only needed for the real WhatsApp version. See [step 6](#6-switching-to-real-whatsapp).

---

## 4. Workflow 1: Tournament Simulator

**Import:** go to **Overview → Create workflow**, then **⋯ (top right) → Import from File** and choose `tournament-simulator.json`.

```
Every Night 9 PM ─┐
                  ├─▶ Simulation Settings ─▶ Read Fixtures ─▶ Read Squads ─▶ Read Results ─▶ Simulate Matches ─┬─▶ Results Rows ─────────────▶ Append Results
Run Manually ─────┘                                                                                           ├─▶ Player Stats Rows ────────▶ Append Player Stats
                                                                                                              └─▶ Knockout Fixture Updates ─▶ Update Fixtures
```

### Configure (one-time)
Open each of the **6 Google Sheets nodes** (Read Fixtures, Read Squads, Read Results, Append Results, Append Player Stats, Update Fixtures):
1. **Credential to connect with:** choose *Google Sheets account*.
2. **Document:** it's set to *By ID*. Replace `PASTE_YOUR_GOOGLE_SHEET_ID` with your sheet ID.
3. **Sheet:** leave it as is (already set by name: Fixtures, Squads, Results, Player Stats).

Then click **Save**.

### Node by node

#### ① Every Night 9 PM (Schedule Trigger)
| | |
|---|---|
| Settings | Trigger interval: Days, every 1 day, at hour 21 |
| Input | nothing (it starts the run) |
| Output | one item with the trigger time, e.g. `{ "timestamp": "2026-10-17T21:00:00+05:30", ... }` |

Only fires while the workflow is **Active** (toggle at the top right).

#### ② Run Manually (Manual Trigger)
| | |
|---|---|
| Settings | none |
| Input | nothing. It runs when you click **Test workflow** |
| Output | one empty item `{}` |

#### ③ Simulation Settings (Edit Fields / Set)
| | |
|---|---|
| Settings | Field `simulateUpTo` (String) = `{{ $now.toFormat('dd LLL yyyy') }}` |
| Input | the trigger item |
| Output | `{ "simulateUpTo": "17 Oct 2026" }` |

**To fast-forward**, replace the expression with fixed text, e.g. `18 Oct 2026`. Every unplayed match up to and including that date gets played. Switch it back to the expression before activating the nightly schedule.

#### ④ Read Fixtures, ⑤ Read Squads, ⑥ Read Results (Google Sheets → Get Row(s))
| | |
|---|---|
| Settings | Operation: Get Row(s) · Document: your sheet ID · Sheet: Fixtures / Squads / Results · **Execute Once** on (Settings tab) so each tab is read only once |
| Input | the previous node's item |
| Output | one item per row, with column names as keys (n8n also adds `row_number`) |

Example output of Read Fixtures (15 items):
```json
{ "row_number": 2, "Match No": 1, "Date": "17 Oct 2026", "Time": "08:00 AM", "Venue": "Academy Ground A",
  "Group": "A", "Team A": "Royal Strikers", "Team B": "Thunder Kings", "Stage": "League", "Format": "T20" }
```
Read Results has **Always Output Data** on, so on day 1 (empty tab) it still outputs one empty item and the workflow keeps going.

#### ⑦ Simulate Matches (Code)
| | |
|---|---|
| Settings | Mode: Run Once for All Items · JavaScript (provided) |
| Input | reads all rows from ③ ④ ⑤ ⑥ by node name |
| What it does | Finds matches dated on or before `simulateUpTo` that have no result yet. For each one it generates a realistic T20 score, every batter's runs/balls/4s/6s, every bowler's overs/runs/wickets, catches and a Player of the Match. After the last league match it works out the points table and fills in the semi-final teams, and after the semis it fills in the final teams. |
| Output | one item |

```json
{
  "simulatedUpTo": "18 Oct 2026",
  "matchesPlayed": 3,
  "log": [
    "Match 4 (18 Oct 2026, League): Storm Riders 113/9 vs Golden Titans 138/3 -> Golden Titans",
    "Match 5 (18 Oct 2026, League): Royal Strikers 177/6 vs Super Smashers 171/4 -> Royal Strikers",
    "Match 6 (18 Oct 2026, League): Thunder Kings 131/9 vs Blue Warriors 101/7 -> Thunder Kings"
  ],
  "newResults": [ { "Match No": 4, "Batted First": "Storm Riders", "Team A Runs": 113, ... } ],
  "newStats":   [ { "Match No": 4, "Player": "Dev G1", "Team": "Storm Riders", "Runs": 31, "Balls": 24, ... } ],
  "fixtureUpdates": []
}
```
Read the `log` to see what was played. If nothing was due, `matchesPlayed` is 0 and nothing is written.

#### ⑧ Results Rows, ⑨ Player Stats Rows, ⑩ Knockout Fixture Updates (Code)
Each one splits one list out of ⑦ into separate items, so the next node writes one row per item.

| Node | Output (one item per row) |
|---|---|
| Results Rows | `{ "Match No": 4, "Batted First": "Storm Riders", "Team A Runs": 113, "Team A Wickets": 9, "Team A Overs": "20", "Team B Runs": 138, "Team B Wickets": 3, "Team B Overs": "16.2", "Result": "Normal", "Winner": "Golden Titans", "Player of the Match": "..." }` |
| Player Stats Rows | `{ "Match No": 4, "Player": "Dev G1", "Team": "Storm Riders", "Runs": 31, "Balls": 24, "Fours": 3, "Sixes": 1, "Overs Bowled": "", "Runs Conceded": "", "Wickets": "", "Catches": "" }` (about 22 per match) |
| Knockout Fixture Updates | `{ "Match No": 13, "Team A": "Super Smashers", "Team B": "Storm Riders" }` (only on 22 and 23 Oct) |

If a list is empty, that branch simply stops. That's normal.

#### ⑪ Append Results, ⑫ Append Player Stats (Google Sheets → Append Row)
| | |
|---|---|
| Settings | Operation: Append Row · Mapping: **Map Automatically** (input field names = column headers) |
| Input | the rows from ⑧ / ⑨ |
| Output | the same rows, now written at the bottom of the Results / Player Stats tab |

#### ⑬ Update Fixtures (Google Sheets → Update Row)
| | |
|---|---|
| Settings | Operation: Update Row · Mapping: Map Automatically · **Column to match on: Match No** |
| Input | `{ "Match No": 13, "Team A": "...", "Team B": "..." }` |
| Output | the updated rows. In the sheet, "Group A Winner" is replaced by the real team name |

### Try it
1. Open **Simulation Settings** and set `simulateUpTo` to `19 Oct 2026`.
2. Click **Test workflow**.
3. Open the sheet. With the demo file, Results now has 9 rows (matches 1–9) and Player Stats has about 200 rows.
4. Click **Test workflow** again. Nothing new is added, because those matches already have results.

To play the tournament in real time instead, put the expression back in ③, **Save**, and switch the workflow to **Active**.

---

## 5. Workflow 2: Help desk (mock version)

**Import** `cricket-whatsapp-helpdesk-mock.json` the same way.

```
Mock WhatsApp Webhook ─▶ Unwrap WhatsApp Payload ─▶ Is Text Message? ──true──▶ Extract Question ─▶ Read Fixtures ─▶ Read Squads ─▶ Read Results ─▶ Read Player Stats ─▶ Build AI Prompt ─▶ Ask Claude ─▶ Mock WhatsApp Reply
                                                                     └─false─▶ Ignore Non-Text
```

### Configure (one-time)
1. **Read Fixtures, Read Squads, Read Results, Read Player Stats:** choose *Google Sheets account* and paste your sheet ID.
2. **Ask Claude:** under **Credential for Header Auth**, choose *Anthropic API Key*.
3. **Build AI Prompt:** if you simulated ahead of the real dates, set `SIMULATED_TODAY` near the top of the code to the simulated date, e.g. `const SIMULATED_TODAY = '19 Oct 2026';`. This keeps "yesterday" and "next match" consistent. Leave it `''` for real use.
4. **Save** and switch the workflow to **Active**.

### Node by node

#### ① Mock WhatsApp Webhook (Webhook)
| | |
|---|---|
| Settings | HTTP Method: POST · Path: `whatsapp-mock` · Respond: **Using 'Respond to Webhook' Node** |
| URLs | Test: `http://localhost:5678/webhook-test/whatsapp-mock` (works after clicking **Listen for test event**, one call per click) · Production: `http://localhost:5678/webhook/whatsapp-mock` (works while the workflow is Active) |
| Input | an HTTP POST with the same JSON body Meta sends for a real WhatsApp message: |

```json
{
  "object": "whatsapp_business_account",
  "entry": [{ "changes": [{ "field": "messages", "value": {
    "messaging_product": "whatsapp",
    "metadata": { "phone_number_id": "MOCK_PHONE_ID" },
    "contacts": [{ "profile": { "name": "Priya" }, "wa_id": "919800000001" }],
    "messages": [{ "from": "919800000001", "type": "text", "text": { "body": "Show me the points table" } }]
  }}]}]
}
```
| | |
|---|---|
| Output | `{ "headers": {...}, "params": {}, "query": {}, "body": { ...the JSON above... } }` |

#### ② Unwrap WhatsApp Payload (Code)
| | |
|---|---|
| What it does | Takes `body.entry[0].changes[0].value`, which is exactly what the real WhatsApp Trigger outputs. That's why every node after this one is identical in both versions |
| Output | `{ "messaging_product": "whatsapp", "metadata": {...}, "contacts": [...], "messages": [ { "from": "919800000001", "type": "text", "text": { "body": "Show me the points table" } } ] }` |

If the body isn't in WhatsApp format, the node stops with a clear error.

#### ③ Is Text Message? (If)
| | |
|---|---|
| Condition | `{{ $json.messages?.[0]?.type }}` is equal to `text` |
| Output | **true** → ④ (normal questions) · **false** → *Ignore Non-Text* (images, voice notes, delivery receipts) |

*Ignore Non-Text* replies to the webhook with `{ "mock": true, "ignored": true, ... }` so the caller never hangs.

#### ④ Extract Question (Edit Fields / Set)
| Field | Expression | Example |
|---|---|---|
| `from` | `{{ $json.messages[0].from }}` | `919800000001` |
| `name` | `{{ $json.contacts?.[0]?.profile?.name \|\| 'Parent' }}` | `Priya` |
| `question` | `{{ $json.messages[0].text.body }}` | `Show me the points table` |

Output: `{ "from": "919800000001", "name": "Priya", "question": "Show me the points table" }`

#### ⑤–⑧ Read Fixtures, Read Squads, Read Results, Read Player Stats (Google Sheets → Get Row(s))
Same as the simulator's read nodes. The output is one item per row of each tab. Read Results and Read Player Stats have **Always Output Data** on, so the bot also works before the first result is entered.

#### ⑨ Build AI Prompt (Code)
| | |
|---|---|
| Settings at the top of the code | `TOURNAMENT_NAME`, `FORMAT`, `SCHEDULE_NOTE`, `POINTS`, `SIMULATED_TODAY` |
| Input | the question from ④ and all sheet rows from ⑤–⑧ (read by node name) |
| What it does | Works out the points table (P/W/L/T/NR, points, net run rate), the semi-final line-up, the top 5 run scorers and wicket takers, and tournament totals for every player. It then writes all of that, plus the fixtures and squads, into Claude's instructions |
| Output | one item, ready to send to Claude |

```json
{
  "from": "919800000001",
  "name": "Priya",
  "question": "Show me the points table",
  "body": {
    "model": "claude-haiku-5-5",
    "max_tokens": 600,
    "system": "You are the friendly WhatsApp help desk of a cricket academy running the Junior Champions T20 Cup 2026 ...\n\nPOINTS TABLE (calculated from results):\nGroup A:\n1. Thunder Kings | P 2 W 2 L 0 ... | Pts 4 | NRR +1.012\n...",
    "messages": [ { "role": "user", "content": "Parent Priya asks: Show me the points table" } ]
  }
}
```
Tip: click this node after a run and open `body.system` to see exactly what Claude was given. It's the fastest way to check the calculations.

#### ⑩ Ask Claude (HTTP Request)
| | |
|---|---|
| Settings | Method: POST · URL: `https://api.anthropic.com/v1/messages` · Authentication: Generic → Header Auth → *Anthropic API Key* · Headers: `anthropic-version: 2023-06-01`, `content-type: application/json` · Body: JSON `{{ JSON.stringify($json.body) }}` |
| Settings tab | **Retry On Fail** on (2 tries) · **On Error: Continue** (so a failed call still produces a polite fallback reply) |
| Input | the `body` from ⑨ |
| Output | Claude's response |

```json
{
  "id": "msg_01...",
  "type": "message",
  "role": "assistant",
  "content": [ { "type": "text", "text": "🏏 Points table after 2 days:\n\nGroup A\n1. Thunder Kings 4 pts (NRR +1.01)\n2. Royal Strikers 2 pts ..." } ],
  "stop_reason": "end_turn",
  "usage": { "input_tokens": 5200, "output_tokens": 140 }
}
```

#### ⑪ Mock WhatsApp Reply (Respond to Webhook)
| | |
|---|---|
| Settings | Respond With: JSON |
| Input | Claude's response from ⑩ |
| Output | the HTTP response sent back to whoever called the webhook. It's the same message the real version would send to WhatsApp |

```json
{
  "mock": true,
  "note": "This is the request that would be sent to the WhatsApp Cloud API",
  "messaging_product": "whatsapp",
  "to": "919800000001",
  "type": "text",
  "text": { "body": "🏏 Points table after 2 days: ..." }
}
```
If Claude failed, `text.body` is the fallback: *"Sorry, I could not fetch the match details right now..."*.

### Ask it questions
From a terminal, in this folder:
```bash
chmod +x test-mock.sh
./test-mock.sh http://localhost:5678/webhook/whatsapp-mock                                   # 8 sample questions
./test-mock.sh http://localhost:5678/webhook/whatsapp-mock "How many runs has Aarav A1 scored?"  # your own
```
Or use **Postman**: POST to the production URL, set Body → raw → JSON, and paste the payload from ①.

Then pick questions from [`sample-questions.md`](sample-questions.md) that match how far you've simulated, and check a few answers against the sheet.

Every run appears under **Executions** (left menu). Click one to see each node's input and output.

---

## 6. Switching to real WhatsApp

Do this once you have a Meta WhatsApp Business app (see the main [README](README.md#3-whatsapp-business-cloud-api-meta-free-tier) for the Meta steps).

1. Create two n8n credentials:
   | Credential type | Fields |
   |---|---|
   | **WhatsApp OAuth API** (used by the trigger) | Client ID = Meta App ID, Client Secret = Meta App Secret |
   | **WhatsApp API** (used to send) | Access Token = permanent system-user token, Business Account ID = WhatsApp Business Account ID |
2. Import `cricket-whatsapp-helpdesk.json`, and configure the 4 sheet nodes and *Ask Claude* exactly as in step 5.
3. **WhatsApp Trigger:** choose the *WhatsApp OAuth API* credential. Updates = `messages`.
   - Output: the same shape as ② above (`{ messaging_product, metadata, contacts, messages }`).
4. **Reply on WhatsApp** (WhatsApp Business Cloud → Send Message):
   | Field | Value |
   |---|---|
   | Credential | *WhatsApp API* |
   | Sender Phone Number (or ID) | replace `PASTE_YOUR_WHATSAPP_PHONE_NUMBER_ID` with your Phone number ID from Meta's API Setup page |
   | Recipient's Phone Number | `{{ $('Build AI Prompt').first().json.from }}` (already set) |
   | Text Body | Claude's answer, with the fallback (already set) |
5. Activate the workflow. n8n registers the webhook with Meta. Your n8n must be reachable over public HTTPS. n8n Cloud already is; for Docker, use a domain or a tunnel such as `ngrok http 5678` and set `WEBHOOK_URL` to that address.
6. Deactivate the mock workflow (it isn't needed any more).

---

## 7. Troubleshooting

| What you see | Likely cause and fix |
|---|---|
| `curl` returns `404` / "webhook not registered" | Workflow isn't Active (production URL), or you used the test URL without clicking **Listen for test event** first |
| Google Sheets node: "Sheet with name … not found" | A tab name doesn't match exactly (`Player Stats` has a space and a capital S) |
| Google Sheets node: 403 / permission error | The Google account you signed in with can't open the sheet, or the Sheets/Drive API isn't enabled in your Google Cloud project |
| Simulator plays **0 matches** | `simulateUpTo` is before 17 Oct, every match up to that date already has a result, or the Date column was converted to real dates (set it to plain text) |
| Simulator skips a semi-final ("teams not decided yet") | Some league matches up to that date have no result. Simulate up to 20 Oct first |
| Columns are shifted after appending | The header row was edited. Headers must exactly match the column list in the README |
| Reply is always "Sorry, I could not fetch the match details…" | Open the execution and click *Ask Claude*. 401 means a wrong API key or header name (must be `x-api-key`); 400 usually means the model name is wrong for your account |
| Bot says "yesterday" wrongly while testing | Set `SIMULATED_TODAY` in *Build AI Prompt* to your simulated date |
| Nightly simulation runs at the wrong hour | Set the n8n / workflow timezone (see step 1) |
| Points or totals look wrong | Open *Build AI Prompt*'s output → `body.system`. That's the calculated table Claude sees. Compare it with the Results tab |
