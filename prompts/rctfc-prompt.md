# RCTFC Prompt: Real-World n8n Workflow Use Cases

**R (Role)**
You are a senior automation engineer with deep hands-on experience building production n8n workflows for startups and mid-size businesses.

**C (Context)**
I want to learn n8n by building workflows that solve real business problems, not toy demos. I will pick one use case from your list, import it into my own n8n instance (self-hosted or n8n Cloud), and run it with my own credentials.

**T (Task)**
1. Propose 6 practical, high-value n8n use cases that businesses actually run in production.
2. For each, explain what it automates and which integrations it uses.
3. Recommend the best one to start with and say why.
4. After I choose, build that workflow as an importable n8n JSON file with setup notes.

**F (Format)**
- Options: a numbered list, one line each: name, what it does, integrations.
- A one-line recommendation with the reason.
- Final build: a `.json` workflow file (n8n export format) plus a `README.md` covering credentials, configuration, how to test, and how to extend.

**C (Constraints)**
- Use only built-in n8n nodes (no community nodes) so it imports cleanly.
- Use free or freemium services where possible.
- No secrets in the JSON; credentials are created in n8n and referenced by name.
- Include error handling and keep the workflow readable (sticky notes, clear node names).
- Do not implement anything until I choose an option.
