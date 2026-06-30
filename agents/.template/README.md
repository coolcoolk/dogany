# .template — mint agent skeleton (batteries-included)

A new agent minted from this template is fully operational with NO hand-wiring:
identity layers + a self-contained Telegram bridge + the long-term memory engine +
Claude hooks + memory/consolidation routines all come baked in.

## What's inside
- Identity (3-layer): CLAUDE.md = loader, RULES.md = shared symlink
  (../../.rules/RULES.md), USER.md = per-agent profile (blank onboarding by
  default), AGENT.md = per-agent identity (onboarding skeleton).
- bridge/ — self-contained agent-sdk Telegram bridge (DGN-053 model: each agent
  runs its OWN bridge; there is no shared bridge). venv is NOT shipped; the mint
  script builds it.
- memory/ — memory.py recall+consolidation core + CONSOLIDATION_TAXONOMY.md.
  state.db is NOT shipped (regenerated on first run).
- .claude/settings.json — hooks: SessionStart recap + onboarding-check,
  UserPromptSubmit memory recall, PreToolUse token-gate.
- routines/ — consolidate-0430 + weekly-review (+ plists), push.sh, lib/,
  cleanup-files. (morning-brief / retro are NOT included — pure proactive-push,
  add per-agent if wanted.)
- memories/MEMORY.md — empty scaffold only (no real data).

## Mint a new agent (recommended)
Use the mint script — it copies, substitutes placeholders, writes .env, builds the
bridge venv, and renames plists:

    ~/dogany/dogany-project/scripts/mint-agent.sh <name> --label <한글라벨> [--token <bot-token>]

It does NOT load launchd or start the bridge (live ops — get approval, then load
the generated plists from bridge/ and routines/ into ~/Library/LaunchAgents).

## Placeholders (the only five the template uses)
The mint script substitutes all of these; never leave one unresolved:
- `__PROJECT_ROOT__`  absolute agent root
- `__AGENT_NAME__`    launchd Label slug + plist filenames
- `__AGENT_LABEL__`   Korean assistant speaker label (memory.py, prompts)
- `__USER_LABEL__`    user honorific (default 형님)
- `__HOME__`          OS user home (PATH / HOME / ~/.claude)

## After minting
1. Set the bot token in .telegram_bot/.env (TELEGRAM_BOT_TOKEN, ALLOWED_USER_IDS).
   Shared runtime config (CLAUDE_CLI_PATH etc) is inherited from ../../.rules/.env,
   so the per-agent .env normally only needs this agent's own token.
2. AGENT.md is still the onboarding skeleton: the first SessionStart runs
   onboarding-check.py to set name/emoji/호칭/tone.
3. RULES.md is a relative symlink (../../.rules/RULES.md) — valid as long as the
   agent lives under the agents/ tree. USER.md is a real per-agent file (fresh
   agent onboards from blank; symlink it to ../../.rules/USER.md only if the agent
   should inherit the owner profile, e.g. the dev agent).
4. Load launchd plists (approval-gated live op).

Env load order (bridge): .telegram_bot/.env > ../../.rules/.env > bridge/.env.
