# Junior Champions T20 Cup 2026: WhatsApp Help Desk (n8n)

A parent sends a WhatsApp message like *"How many runs has Aarav scored?"*, *"Show me the points table"* or *"Where is the final?"* to the academy's WhatsApp number about the **Junior Champions T20 Cup 2026**, an 8-team T20 tournament. n8n reads the tournament sheet, calculates the standings and player stats, Claude writes a short answer using only that data, and the reply goes back to **that parent's number only**.

```
WhatsApp Trigger → Is Text Message? → Extract Question → Read Fixtures → Read Squads → Read Results → Read Player Stats
  → Build AI Prompt (points table, NRR, semi-final line-up, top scorers) → Ask Claude → Reply on WhatsApp
```

> **New to n8n?** Follow the [step-by-step setup guide](SETUP-GUIDE.md). It covers every credential and every node's settings, input and output.

## Tournament format (7 days, 17–23 Oct 2026)
| Day | Date | Matches |
|---|---|---|
| 1–4 | 17–20 Oct | League: two groups of 4, each team plays the other 3 in its group (12 matches, 3 a day) |
| 5 | 21 Oct | Reserve day for rain-affected league matches |
| 6 | 22 Oct | Semi-finals: Group A winner vs Group B runner-up, Group B winner vs Group A runner-up |
| 7 | 23 Oct | Final |

Points: win 2, tie or no result 1, loss 0. Teams level on points are split by net run rate.

## Files
| File | What it is |
|---|---|
| `cricket-whatsapp-helpdesk.json` | The help desk. Import into n8n (Workflows → Import from File) |
| `cricket-whatsapp-helpdesk-mock.json` | Same help desk with WhatsApp mocked, for testing without Meta credentials |
| `tournament-simulator.json` | Plays the matches for you (random but realistic scores) so you can test the whole 7 days |
| `tournament-fixtures-template.xlsx` | Clean sheet for tomorrow: fixtures, squads, and empty Results and Player Stats tabs |
| `tournament-demo-data.xlsx` | Same sheet with days 1–2 already played, for testing mid-tournament questions straight away |
| `SETUP-GUIDE.md` | Step-by-step n8n setup with each node's input and output |
| `sample-questions.md` | 30 parent questions grouped by tournament phase |
| `test-mock.sh` | Sends fake parent messages to the mock workflow and prints the replies |

## The sheet
| Tab | Columns | Who fills it |
|---|---|---|
| **Fixtures** | `Match No, Date, Time, Venue, Group, Team A, Team B, Stage, Format` | Set up once. Semi-final and final teams start as placeholders (`Group A Winner`, `Winner SF1`) and are replaced when known |
| **Squads** | `Team, Group, Players` (players comma-separated) | Set up once |
| **Results** | `Match No, Batted First, Team A Runs, Team A Wickets, Team A Overs, Team B Runs, Team B Wickets, Team B Overs, Result, Winner, Player of the Match` | One row per match. `Result` is `Normal`, `Tie` or `No Result`. Overs like `19.4` |
| **Player Stats** | `Match No, Player, Team, Runs, Balls, Fours, Sixes, Overs Bowled, Runs Conceded, Wickets, Catches` | One row per player per match (leave blanks where they didn't bat or bowl) |

Team A and Team B in Results always mean the Team A and Team B of that match in Fixtures. You never type the points table or tournament totals: the help desk works them out from these rows every time a parent asks.

## How the data gets updated each day
- **Real tournament:** after each match the scorer adds one Results row and the player rows. The next parent question already sees the new score, points table and top scorers. Typing a result directly into Google Sheets from a phone works fine. If the scorer would rather not touch the sheet, a Google Form that writes into these tabs is an easy add-on.
- **Simulation (testing):** the Tournament Simulator plays the scorer's part:
  1. Import `tournament-simulator.json` and set the same sheet ID in all 6 Google Sheets nodes.
  2. **Day by day:** activate it. Every night at 9 PM it plays that day's matches (17 Oct, then 18 Oct, and so on), fills in the semi-final teams from the points table after 20 Oct, and the final teams after the semis.
  3. **Fast-forward:** open *Simulation Settings*, set `simulateUpTo` to a date such as `20 Oct 2026`, and click *Test workflow*. Every unplayed match up to that date is played at once. Run it again with `23 Oct 2026` to finish the tournament.
  4. Running it twice never duplicates a match. To start over, delete the data rows in Results and Player Stats and put the placeholder names back in Fixtures rows 13–15.
  5. When testing ahead of the real dates, set `SIMULATED_TODAY` at the top of the help desk's **Build AI Prompt** node (e.g. `'19 Oct 2026'`) so "yesterday" and "next match" line up with the simulation. Set it back to `''` for real use.

## Important: groups vs direct messages
The official WhatsApp Business Cloud API (what n8n uses) **cannot read messages inside a normal WhatsApp group**. The working setup is:
1. Get a dedicated academy WhatsApp Business number (it must not be in use on the regular WhatsApp app).
2. Post one message in the parents' group: *"For fixtures, scores, points table and player stats, message this number: +91 XXXXX XXXXX. You'll get an instant reply."*
3. Parents message that number directly, and each one gets a private answer.

Unofficial tools that scrape group chats exist, but they break WhatsApp's terms and the number can get banned, so they're not used here.

## No WhatsApp credentials yet? Use mock mode
The mock workflow is the real workflow with only the two WhatsApp nodes swapped out, so the data, calculations, Claude prompt and answers are identical:

| Real workflow | Mock workflow |
|---|---|
| WhatsApp Trigger (needs Meta app) | **Mock WhatsApp Webhook**: a plain n8n webhook that accepts the same JSON Meta sends |
| Reply on WhatsApp (sends a message) | **Mock WhatsApp Reply**: returns the message that *would* be sent (recipient number + text) as the HTTP response |

You still need the Google Sheets credential and the Anthropic API key (steps 1, 2, 4 and the sheet IDs from step 5 below). Skip step 3.

1. Import `cricket-whatsapp-helpdesk-mock.json`, set the sheet ID in the 4 **Read …** nodes, and pick your credentials.
2. Activate the workflow.
3. Run the test script with the production webhook URL shown on the **Mock WhatsApp Webhook** node:
   ```bash
   ./test-mock.sh http://localhost:5678/webhook/whatsapp-mock
   ./test-mock.sh http://localhost:5678/webhook/whatsapp-mock "How many wickets has Neel B11 taken?"
   ```
   Each fake parent has a different phone number, and each reply shows the number it would go to, so you can confirm answers reach only the parent who asked.
4. Prefer Postman? POST any of the payloads in `test-mock.sh` to the same URL.

When you get WhatsApp credentials, import `cricket-whatsapp-helpdesk.json` instead and follow step 3. Nothing else changes.

## Setup

### 1. Put the data in Google Sheets
1. Upload `tournament-fixtures-template.xlsx` (or `tournament-demo-data.xlsx` for testing) to Google Drive and open it with Google Sheets (File → Save as Google Sheets).
2. Keep the four tabs and headers exactly as described in [The sheet](#the-sheet).
3. Copy the sheet ID from the URL: `docs.google.com/spreadsheets/d/<THIS_PART>/edit`.

If your real xls has different column names, either rename the headers or edit the names in the **Build AI Prompt** Code node.

### 2. Set the tournament details
At the top of the **Build AI Prompt** Code node, edit:
```js
const TOURNAMENT_NAME = 'Junior Champions T20 Cup 2026';
const FORMAT = 'T20 (20 overs per side)';
const SCHEDULE_NOTE = '7 days: league 17-20 Oct, 21 Oct reserve day ...';
const POINTS = { win: 2, tie: 1, noResult: 1 };
```

### 3. WhatsApp Business Cloud API (Meta, free tier)
1. Go to developers.facebook.com → Create App → **Business** → add the **WhatsApp** product.
2. Under WhatsApp → API Setup, add and verify the academy's phone number. Note the **Phone number ID**.
3. Create a **permanent access token** (Business Settings → System Users → Generate token with `whatsapp_business_messaging` and `whatsapp_business_management`).
4. In n8n create two credentials:
   - **WhatsApp API** (used for sending): Access Token + Business Account ID.
   - **WhatsApp OAuth API** (used by the trigger): App ID + App Secret.
5. Activate the workflow. n8n registers the webhook with Meta automatically. Your n8n must be reachable over public HTTPS (n8n Cloud works as is; self-hosted needs a domain or a tunnel).

Replying to a message a parent sent is free within 24 hours of their message, so normal Q&A has no template or approval overhead.

### 4. Claude API key
1. Get a key at console.anthropic.com.
2. In n8n create a **Header Auth** credential named `Anthropic API Key`: Name `x-api-key`, Value = your key.

The workflow uses `claude-haiku-5-5`, which is fast and cheap: even with all 15 matches of stats in the prompt, a whole tournament's worth of questions costs very little. Change `model` in the Build AI Prompt node if you prefer another model.

### 5. Fill in the placeholders
- **Read Fixtures, Read Squads, Read Results, Read Player Stats**: replace `PASTE_YOUR_GOOGLE_SHEET_ID`.
- **Reply on WhatsApp**: replace `PASTE_YOUR_WHATSAPP_PHONE_NUMBER_ID`.
- Pick the matching credential on each node (open the node and choose it from the dropdown).

## Test it
1. Run the simulator up to the phase you want to test (or use the demo sheet, which has days 1–2 played).
2. Ask the questions in [`sample-questions.md`](sample-questions.md), from your phone (real workflow, with your number added as a test recipient in Meta's API Setup) or with `test-mock.sh` (mock workflow).
3. Cross-check a couple of answers against the sheet, e.g. a player's total runs or a team's points.
4. Check **Executions** in n8n if no reply arrives.

## How it behaves
- Answers only from the sheet and never invents scores, timings or venues.
- Calculates the points table, net run rate, semi-final line-up, top run scorers and wicket takers fresh on every question, so it is always current.
- Finds a child's team from the Squads tab when a parent asks by player name, then gives their personal stats and their team's next match.
- Works before the first result is entered (empty Results and Player Stats tabs are fine).
- Images, voice notes and delivery receipts are ignored by the "Is Text Message?" filter.
- If Claude is unreachable, it retries once and then sends a polite "please try again or contact the office" message, so a parent is never left without a reply.

## Easy extensions
- **Scorer form**: a Google Form (or an n8n Form Trigger) that writes into Results and Player Stats, so the scorer never opens the sheet.
- **Match-end broadcast**: when a Results row is added, message all registered parents the score (requires an approved WhatsApp template).
- **Log questions**: append each question and answer to a "Log" tab to see what parents ask most.
- **Hindi or other languages**: add "Reply in the same language the parent uses" to the system prompt rules.
