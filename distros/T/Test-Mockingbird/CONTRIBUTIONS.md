# Contributing Guidelines

Thank you for your interest in contributing.
This project follows strict engineering standards to ensure long‑term maintainability, reliability, and clarity.
All contributors must follow the guidelines below.

---

## Testing Standards

### Test Files
Every module must be covered by three test files:

- `t/function.t` — function‑level tests (white‑box + black‑box)
- `t/unit.t` — unit tests for internal/private routines (white‑box)
- `t/integration.t` — integration tests (black‑box only)

Each file must contain subtests grouped by feature or routine.

### Test Framework
- Use **Test::Most** for all test files.
- Use `use_ok`, `new_ok`, `lives_ok` where appropriate.
- Use **Test::Warnings** to ensure no unexpected warnings.
- Use **Test::Deep** for structural comparisons.
- Use **Test::Mockingbird::DeepMock** or **Test::Mockingbird** exclusively for mocking/spying.

### Coverage Requirements
- All contributions must maintain or improve **Devel::Cover** metrics.
- Aim for **95%+ overall coverage** and **100% for critical modules**.
- Where possible, design tests to achieve **high LCSAJ scores** to maximize control‑flow coverage.

---

## Code Quality Standards

### Error Handling
- Use `croak` and `carp` in modules.
- Use `die` only in CLI scripts.

### Coding Style
- Comment thoroughly — at least one comment every 5 lines.
- No bareword filehandles.
- No indirect object syntax.
- All modules must `use strict` and `use warnings`.
- Tabs, not 4 character, indentation

### Static Analysis
- Code must pass **Perl::Critic** with the project’s curated policy set.
- No unused variables (enforced via Test::Vars or Test::Strict).

---

## Documentation Standards

Every routine must have complete POD including:

- Purpose
- Arguments
- Return values
- Side effects
- Notes
- API Specification:
  - `=head3 API`
  - `=head4 Input` — schema compatible with **Params::Validate::Strict**
  - `=head4 Output` — schema compatible with **Returns::Set**

### POD Quality Tests
All contributions must pass:

- **Test::Pod**
- **Test::Pod::Coverage**

### Helper Routines (routines that start with _)


#### NAME
_routine_name

#### PURPOSE
Brief description of what this helper does.

#### ENTRY CRITERIA
- List of required arguments
- Expected types or shapes
- Preconditions that must be true

#### EXIT STATUS
- What the routine returns
- Whether it may croak

#### SIDE EFFECTS
- Any symbol table changes
- Any global state changes
- Any warnings or output

#### NOTES
- Internal only, not part of public API
- Any assumptions or invariants

---

## Change Tracking

Every feature or fix must include:

- A **single‑line entry** in `Changes` describing the change.
- Semantic versioning:
  - Patch: bug fixes
  - Minor: new features
  - Major: breaking changes

---

## Mocking Standards

- Use **DeepMock** or **Test::Mockingbird** exclusively.
- Do not mix mocking frameworks.
- Nested mocking scopes are not supported unless explicitly documented.

---

## Project Structure

- All examples must go in `examples/`.
- All tests must go in `t/`.
- All modules must go in `lib/`.

---

## Pull Request Requirements

A pull request must include:

1. Code changes  
2. Updated tests  
3. Updated documentation  
4. A one‑line changelog entry  
5. Passing CI (coverage, critic, POD, warnings)

Pull requests that do not meet these requirements will be returned for revision.

---

## Thank You

Your contributions help maintain a high‑quality, reliable codebase.  
By following these standards, you ensure the project remains robust, maintainable, and a pleasure to work on.
