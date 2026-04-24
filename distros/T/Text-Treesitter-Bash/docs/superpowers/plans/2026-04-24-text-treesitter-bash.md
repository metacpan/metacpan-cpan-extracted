# Text::Treesitter::Bash Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a CPAN distribution that parses Bash and extracts executable command units for approval flows.

**Architecture:** Vendor the compatible Bash tree-sitter grammar in `share/`, load it through `Text::Treesitter`, and keep command extraction separate from security findings. The parser returns raw structural facts; callers own final allow/deny policy.

**Tech Stack:** Perl 5.26, Dist::Zilla, `Text::Treesitter`, `File::ShareDir`, `Path::Tiny`, `Test2::V0`.

---

## Chunk 1: Distribution Scaffold

- [x] Create `dist.ini`, `cpanfile`, `Changes`, `README.md`, `.gitignore`.
- [x] Vendor `tree-sitter-bash` `v0.20.5` under `share/tree-sitter-bash`.

## Chunk 2: Tests

- [x] Create `t/00_load.t`.
- [x] Create `t/10_commands.t` for list, pipeline, and command substitution extraction.
- [x] Create `t/20_findings.t` for shell interpreter and `curl | sh` findings.

## Chunk 3: Implementation

- [x] Create `lib/Text/Treesitter/Bash.pm`.
- [x] Implement runtime share lookup with development fallback.
- [x] Copy grammar sources to a temporary build directory before loading.
- [x] Implement `parse`, `commands`, and `findings`.

## Chunk 4: Verification

- [x] Run focused tests with `prove -l t`.
- [x] Run `dzil test`.
