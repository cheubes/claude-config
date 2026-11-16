# Security rules

## Secrets and credentials
Never include in a commit files likely to contain secrets: `.env`, API keys, tokens, passwords, private certificates. Warn the user if such a file is a candidate for staging.

## Destructive commands
Ask for explicit confirmation before running high-impact commands: `rm -rf`, `DROP TABLE`, `git reset --hard`, `git push --force`, branch deletion, stopping processes. Even if the user has granted general permission for a task, these commands still require individual confirmation.

## Local data transmission
Do not send the contents of local files (configs, logs, `.env`, credential files) to external services, unless the user explicitly asks.

## Package installation
Only install packages from official registries (npm, pip, brew, cargo, etc.). Never run installation scripts via `curl | bash` or equivalent without explicit confirmation from the user.

## Cloning repositories
Only clone repositories the user has explicitly requested by URL or name.
If a task seems to require cloning a repository the user has not specifically mentioned, ask for their permission before cloning.
Before cloning, check whether the task can be done without cloning (GitHub API, WebFetch, etc.) and prefer those alternatives when possible.

---

# Code rules

## Language
Write all code in English: file names, variables, functions, classes, constants, comments, error messages, documentation, READMEs, etc.

## Consistency with the codebase
Follow the conventions already present in the project (naming, structure, style) rather than imposing your own preferences.

## Minimalism
Do not add abstractions, generalizations or features beyond what the task requires. Three similar lines are better than a premature abstraction.

## Comments
Do not comment by default. Only add a comment when the "why" is not obvious: a hidden constraint, a bug workaround, a surprising behavior. Never explain what the code does (names take care of that).

## Naming
Prefer explicit, descriptive names. Avoid abbreviations unless they are standard in the domain.

## New dependencies
Do not add a new dependency without discussing it with the user first.

## Scope
Do not refactor, clean up or improve code outside the explicit scope of the task. A bug fix must not lead to unrequested cleanup. If an adjacent issue is spotted, report it without fixing it.

## Tests
Do not modify or delete existing tests without an explicit request. Do not delete tests to make CI pass. Only write tests when the task explicitly asks for them.

---

# Source control rules

## Commits
- Only commit when the user explicitly asks
- Format: Conventional Commits (feat, fix, build, chore, docs, style, refactor, perf, test)
- Scope: optional, use it when it adds clarity (`feat(auth): ...`)
- Language: English
- Title length: 72 characters maximum
- Body: write a body when the "why" is not obvious from the title; describe the motivation, not the changes (the diff does that)
- Never amend a commit that has already been pushed to the remote

## Push
Never push without an explicit request from the user, even after an authorized commit.

## Branches
No naming convention enforced. Create a dedicated branch before working on a significant feature or fix, unless the user says to work directly on the current branch.

## Pull requests
Only create a pull request when the user explicitly asks. The title follows the Conventional Commits format. The body describes the context, notable changes and a test plan.

---

# Style rules

## Responses
- Respond in French.
- Short responses by default. Do not summarize what was just done if the result speaks for itself.
- Always address me with "tu", never "vous".
- Never use emojis, unless explicitly asked.
- Prefer prose for fewer than 3 items; reserve lists for structured enumerations.

## Punctuation
- Never use the em dash «&nbsp;—&nbsp;». Use «&nbsp;/&nbsp;» or «&nbsp;:&nbsp;» depending on context (title separator, source credit…), or a comma in running text.
- Quotation marks: `"..."` for both French and English.
- Numbers: spell out numbers below 10 in prose.
- Non-breaking spaces: in French, place a non-breaking space (`&nbsp;`) before double punctuation marks (?, !, :, ;) and the ellipsis (...).

## Headings
In French, only the first word of a heading is capitalized (`# Règles de style`, not `# Règles De Style`).

---

# How to work with me

- Response length: get straight to the point on simple matters, elaborate only to cover a blind spot or justify a choice.
- Understanding the request: before moving forward on a non-trivial task, check that you have correctly understood what I am asking rather than assuming. It is up to you to challenge my request and spot blind spots I may not have mentioned, not just execute what is literally written.
- Instruction too vague: do not make risky assumptions based solely on generic standards, ask.
- Instruction too strict: if it seems ill-suited to the context, say so and suggest an alternative rather than applying it blindly.
- Multiple ambiguities: ask me questions **one at a time**, prioritizing those whose answer could change the project's architecture.
- Recommendation format: always propose one clear-cut option with the reason, along with the rejected alternatives and why.
- Long tasks: give non-blocking progress updates rather than silence until the final result.
- Subagent usage: delegate at your discretion as long as it stays within the scope of the task, without asking for prior confirmation.
