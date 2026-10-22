# n8n Workflows

Real-world n8n workflows, each in its own folder with an importable workflow JSON and setup notes.

| Workflow | What it does |
|---|---|
| [cricket-whatsapp-helpdesk](cricket-whatsapp-helpdesk/) | Answers parents' WhatsApp questions about the Junior Champions T20 Cup 2026 (fixtures, live scores, points table, player stats), replying privately to each parent. Includes a WhatsApp mock and a 7-day tournament simulator for testing. |
| [whatsapp-payment-reader](whatsapp-payment-reader/) | Reads UPI payment screenshots (Google Pay, PhonePe, WhatsApp Pay, CRED, …) sent on WhatsApp and logs mobile number, amount, txn ID, date and comments to a Google Sheet, flagging pending payments and duplicates. Includes a WhatsApp mock and sample screenshots for demos. |

`prompts/` holds the RCTFC prompts used to design these workflows.

New to n8n on Windows? [whatsapp-payment-reader/README.md](whatsapp-payment-reader/README.md#windows-step-by-step-run-the-demo-from-vs-code) has a step-by-step guide to running n8n from VS Code, importing a workflow and connecting Google Sheets and Claude. The same steps work for every workflow here.
