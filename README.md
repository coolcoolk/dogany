# Dogany

Self-hostable, always-on **multi-agent organization** that runs on Claude Code and
lives on Telegram. Mint a new agent with a single command and it comes
batteries-included — its own bridge, a self-organizing long-term memory engine,
Claude hooks, and scheduled routines — no hand-wiring.

> Sell the layer, not the content: agents run on your own Claude Code compute (BYO),
> and the value is the org around them — memory that curates itself, agents that
> proactively reach out, and (on the roadmap) a console to observe and steer them.

## What's here
- `agents/.template/` — batteries-included agent skeleton (bridge + memory + hooks +
  routines). Minting copies this and substitutes placeholders.
- `scripts/mint-agent.sh` — mint a new self-contained agent from the template.
- `skills/` — framework skills (skill-creator, memory-search, cron-register,
  proactive-push, reminder, user-onboarding).
- `service/` — shared module layer (SDK for skills) over the lifekit data layer.
- `database/` — lifekit schema (code only; personal data is gitignored).
- `rules/` — shared RULES + a USER profile example.

## Mint an agent
```sh
scripts/mint-agent.sh <name> --label <speaker-label> [--token <telegram-bot-token>]
```
It copies the template, substitutes the five placeholders
(`__PROJECT_ROOT__`, `__AGENT_NAME__`, `__AGENT_LABEL__`, `__USER_LABEL__`, `__HOME__`),
writes `.env`, and builds the bridge venv. Loading launchd is a deliberate manual step.
See `agents/.template/README.md` for details.

## Design
Each agent is self-contained (its own bridge + memory). Agent-specific values are
placeholders resolved at mint time. Secrets, runtime state, and personal data
(`.env`, `agents/<name>/`, memories, databases, sessions) are gitignored and never
shipped.

## License
MIT — see [LICENSE](LICENSE).
