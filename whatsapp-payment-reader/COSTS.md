# Running costs

What it costs to run the payment reader for **250 screenshots a month**, checked on 22 Oct 2026.

**Total: about ₹2,460 ($28) a month on n8n Cloud, or about ₹920 ($10.50) a month if you self-host n8n**, plus 18% GST. n8n is most of the cost. Reading each screenshot with Claude costs about ₹1.7.

## Cost per item

| Item | Per screenshot | 250 / month |
|---|---|---|
| **WhatsApp Cloud API** (direct from Meta) | ₹0 | **₹0**. Messages customers send you are free, and you get 1,000 free replies per number each month |
| WhatsApp through a reseller (BSP, e.g. AiSensy, Interakt) | ₹0 + markup | ₹1,500 to ₹6,000 platform fee |
| **Claude Sonnet 5.5** (the default model) | ~$0.019 ≈ ₹1.7 | **~$4.80 ≈ ₹420** |
| Claude Haiku 5.5 (cheaper option) | ~$0.001 ≈ ₹0.08 | ~$0.24 ≈ ₹21 |
| **n8n Cloud Starter** (2,500 runs a month) | – | **€20 ≈ ₹2,040** (yearly billing) |
| n8n self-hosted (free software on a small server) | – | ~₹500 for the server |

## Monthly totals

| Setup | Per month | Per screenshot |
|---|---|---|
| Meta direct + Sonnet 5.5 + n8n Cloud Starter | ≈ ₹2,460 ($28) | ≈ ₹9.8 |
| Meta direct + Sonnet 5.5 + self-hosted n8n | ≈ ₹920 ($10.50) | ≈ ₹3.7 |
| Meta direct + Haiku 5.5 + self-hosted n8n | ≈ ₹520 ($6) | ≈ ₹2.1 |

Add the BSP fee if you go through a reseller instead of Meta directly. All amounts are before 18% GST.

## How the numbers were worked out

**WhatsApp.** Meta does not charge for messages customers send to you. Since 1 Oct 2026, replies inside the 24-hour customer service window are no longer unlimited and free: each business number gets 1,000 free service messages a month, and each one after that costs the utility rate, ₹0.115 ($0.0014) in India. The workflow sends one reply per screenshot, so 250 replies fit inside the free 1,000.

**Claude.** Each request is the screenshot plus the ~1,000-token extraction prompt, with replies capped at 1,024 tokens (`max_tokens` in **Build Extraction Request**). A full-size phone screenshot (1080×2400) is about 3,350 image tokens, so one request is about 4,400 input tokens and at most 1,024 output tokens.
- Sonnet 5.5 ($2 in / $10 out per million tokens): 4,400 × $2/M + 1,024 × $10/M ≈ $0.019
- Haiku 5.5 ($0.10 in / $0.50 out per million tokens): ≈ $0.001

This is the most a screenshot should cost. WhatsApp usually compresses images, and replies are usually shorter than the cap, so real costs will likely be lower.

**n8n.** One screenshot is one workflow run, so 250 runs fit easily inside Starter's 2,500. Self-hosting the free Community Edition only costs the server.

## Assumptions
- ₹88 = $1 and €1 ≈ ₹102.
- One confirmation reply per screenshot.
- The ~₹500/month server for self-hosting is an estimate for a small cloud VM, not a published price.
- Prices change. Check the sources below before quoting them to anyone.

## Sources
- [Meta: WhatsApp Business Platform pricing](https://developers.facebook.com/documentation/business-messaging/whatsapp/pricing)
- [India per-message rates, Oct 2026](https://www.flowcall.co/blog/whatsapp-business-api-pricing)
- [Indian BSP fee ranges](https://dev.to/xreach51/whatsapp-business-api-pricing-in-india-2026-every-layer-of-the-bill-12i7)
- [Claude: how image tokens are counted](https://platform.claude.com/docs/en/build-with-claude/vision)
- [Claude API pricing](https://claude.com/pricing)
- [n8n pricing](https://n8n.io/pricing/)
