---

```markdown
# tstregex

**A high-precision regex anatomy and diagnostic tool.**

`tstregex` is a command-line utility designed to provide surgical insights into Perl regular expressions. Unlike standard matchers, it uses a custom "nibbling" engine to tokenize patterns and provide exact, character-level failure diagnostics. Whether you are debugging complex nested groups or hardening patterns against ReDoS, `tstregex` provides the engine you need to see exactly what is happening under the hood.

### Visual Diagnostic

**Command:** `$ perl lib/Tstregex.pm '/^[a-z]*\d{3}$/' 'abc123' 'abc12a'`

**Output:** abc123  
abc**12a** (^[a-z]***\d{3}$**)

---

## Features

* **Surgical Diagnostics:** Real-time failure tracking with the `^--- HERE` marker.
* **Smart Scanning:** Automatically unwraps regex delimiters (`//`, `m!!`, `m{}`) and extracts modifiers (`i`, `s`, `x`).
* **Nibbling Engine:** Custom tokenizer that handles quantifiers, complex assertions (lookaheads), and nested structures without confusion.
* **Hardened Security:** Built-in "Death Tests" to detect catastrophic backtracking and exponential complexity (ReDoS protection).
* **Cross-Platform:** Fully stabilized for Linux, Cygwin, and Windows (Strawberry Perl).

---

## Installation

### Prerequisites
* Perl 5.30 or higher.
* `make` (Linux/Cygwin) or `gmake` (Windows/Strawberry Perl).

### Setup
Download the distribution and run the following commands in your terminal:

```cmd
perl Makefile.PL
gmake
gmake install
```

---

## Usage

### Basic Matching
Test a simple pattern against a string:
```bash
tstregex "(\d{2})/(\d{2})/\d{4}" "21/07/1985"
```

### Enriched Diagnostic Mode (`-d`)
If a regex fails, use the `-d` flag to see exactly where the engine stopped:
```bash
tstregex -d "abc(def" "abc"
```

### Verbose Mode (`-v`)
Get detailed tokenization and matching telemetry:
```bash
tstregex -v "abc**" "abc"
```

---

## Project History

* **Genesis (March 2026):** Initially a procedural script for internal regex validation.
* **Modularization:** Refactored into a formal Perl module (`TstRegex.pm`).
* **Stabilization:** Hardened for Windows/Strawberry Perl with robust signal handling (`$SIG{__DIE__}`) to capture native Perl syntax errors.

---

## License

This software is released under the same terms as Perl itself.

---

```

---
