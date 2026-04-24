# Text::Treesitter::Bash Design

## Goal

Create a Perl distribution that ships a Bash tree-sitter grammar and exposes a
security-oriented command extraction API for agent approval flows.

## Architecture

`Text::Treesitter::Bash` has two layers. The parsing layer loads the vendored
`tree-sitter-bash` grammar through `Text::Treesitter` and returns parse trees.
The analysis layer walks the Bash syntax tree and returns executable command
entries with operator and nesting context.

Security policy remains separate from parsing. `findings` reports neutral facts
such as shell interpreters, dynamic code flags, and network output piped into a
shell; callers decide whether those findings require denial, approval, or LLM
review.

## Runtime Data

The grammar sources live under `share/tree-sitter-bash`. At runtime they are
copied to a temporary directory before `Text::Treesitter` compiles the grammar,
so installed share files are never modified.

The vendored grammar is `tree-sitter-bash` `v0.20.5` because Debian bookworm
ships `libtree-sitter-dev` `0.20.7`, whose ABI is older than current
`tree-sitter-bash` generated parsers.

## Public API

`parse($source)` returns a `Text::Treesitter::Tree`.

`commands($source)` returns hashrefs with `source`, `command`, `argv`,
`start_byte`, `end_byte`, `context`, `before_op`, and `after_op`.

`findings($source)` returns hashrefs with `type`, `message`, and related command
entries.

## Tests

Tests cover module loading, command extraction across `&&`, `||`, `;`, and
pipelines, command substitutions, and security findings for `curl | sh` and
dynamic interpreter execution.
