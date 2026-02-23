# Repository Guidelines

## Project Structure & Module Organization
This repository is a MoonBit module (`moon.mod.json`) with source rooted at `src/`.

- `src/lib/nanoid.mbt`: main library implementation and public API.
- `src/lib/nanoid_test.mbt`: black-box tests for library behavior and edge cases.
- `src/top.mbt`: demo executable entrypoint.
- `src/moon.pkg`, `src/lib/moon.pkg`: package boundaries and imports.
- `_build/` and `target/`: generated build artifacts (do not edit manually).

Keep new code package-local and organized by feature. In MoonBit, file names are organizational only; package paths come from module/package metadata, not file names.

## Build, Test, and Development Commands
- `moon check --target all`: fast type-check across all backends.
- `moon test --target all`: run the full test suite (same core check used in CI).
- `moon run src`: run the demo app in `src/top.mbt`.
- `moon fmt`: apply canonical formatting before committing.
- `moon info`: regenerate/check `pkg.generated.mbti` interface snapshots when public APIs change.

## Coding Style & Naming Conventions
Follow existing MoonBit style in `src/lib/nanoid.mbt`:

- Use 2-space indentation and keep blocks readable with `///|` section delimiters.
- Prefer `snake_case` for function names and local variables.
- Use `PascalCase` for public types and enum variants (for example, `NanoidError`, `SizeTooSmall`).
- Favor explicit `Result`-based error handling over panics for public APIs.
- Run `moon fmt` for all formatting decisions.

## Testing Guidelines
- Add tests in `*_test.mbt` files, usually beside the package they verify (for example, `src/lib/nanoid_test.mbt`).
- Name tests descriptively with snake_case strings: `test "edge_cases_and_boundaries"`.
- Cover happy paths, invalid inputs, boundary limits, and Unicode behavior.
- Run `moon test --target all` locally before opening a PR.

## Commit & Pull Request Guidelines
Recent history follows Conventional Commit-style prefixes: `fix:`, `feat:`, `refactor:`, `perf:`, `chore:` (with occasional breaking form like `refactor!:`). Use concise imperative summaries.

For PRs:
- Explain what changed and why.
- Link related issues when applicable.
- Include test evidence (for example, `moon test --target all` output summary).
- Update `README.md`/`CHANGELOG.md` when behavior or public API changes.
