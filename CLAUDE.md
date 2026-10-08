# Working in this repository

Instructions for anyone, person or agent, committing to Centauri. They apply to every branch.

## Commits

- Every commit MUST be authored and committed as `DevParapalli <hey@parapalli.dev>`. Set it locally before the first commit: `git config user.name DevParapalli && git config user.email hey@parapalli.dev`.
- Commit messages MUST NOT carry `Co-Authored-By`, `Claude-Session`, `Generated with` or any other AI attribution trailer or line, whatever the tooling suggests. No model name or identifier appears in a commit message, a pull request, a code comment or any file.
- Messages follow Conventional Commits: `feat: …`, `fix: …`, `docs: …`, `chore: …`. The subject is one line in sentence case; the body, when there is one, says what changed and why in full sentences.
- Trunk is `main`. Work on branches named `feat/…` or `fix/…` and merge with a pull request.

## What is where

- `lib.typ` is the entry point; `src/make.typ` builds documents, `src/slides.typ` builds decks, `src/tokens.typ` reads `src/tokens.toml`.
- `src/tokens.toml` MUST NOT be edited by hand. It is written by `uv run scripts/sync-tokens.py --ref vX.Y.Z` from the Proxima tag of the same version, or `--from ../proxima/tokens.toml` against a checkout.
- `docs/reference.md` is the complete reference and MUST document every name `lib.typ` exports, and no other; `docs/deck-board.md` is the deck design rationale. The screen half of the same decks is `slidev-theme-proxima` in the Proxima repository under `deck/`.

## Checks before a commit

- `tests/run.sh` from the repository root MUST pass. It needs `typst` 0.15 or later, `pdftotext`, and the fonts in `fonts/` (`--font-path fonts`).
- Tests ship with any behaviour change: a new component gets a reference entry and, where it has a build rule, a test that the rule fires.

## Releases

Centauri follows Proxima: a Proxima tag `vX.Y.Z` fixes the tokens, and the Centauri release with the same version vendors them. Bump `typst.toml` and the README's version note together.
