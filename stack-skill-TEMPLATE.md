---
name: stack-<name>
description: <When to load: list the triggers — file extensions, service/repo names, task keywords.>
---

# Stack: <name>

For the worker: load before the first edit.

## Source of truth
- Repo / host / path of the production copy. What is NOT the truth (stale copies, etc.).

## How to verify
- Exact commands (verify.sh, tests, smoke request). Only what actually works.

## Patterns
- How this code is conventionally written, with examples `path:line`.

## Pitfalls
- What happened → rule. (Source: where it was found.)

## Stop zones
- What is done only with an explicit "yes" from the user: production, money, DB migrations, releases.
