# Test::Spelling::Stopwords

> POD spell-checking with automatic project-specific stopwords - a lean,
> drop-in complement to [Test::Spelling](https://metacpan.org/pod/Test::Spelling).

[![CPAN version](https://badge.fury.io/pl/Test-Spelling-Stopwords.svg)](https://metacpan.org/release/Test-Spelling-Stopwords)
[![Perl](https://img.shields.io/badge/Perl-5.14%2B-blue)](https://www.perl.org)
[![License](https://img.shields.io/badge/license-Apache%20License%202.0-blue)](http://www.perlfoundation.org/artistic_license_2_0)

---

## The Problem

Standard POD spell-checking with `Test::Spelling` requires you to manually
maintain a list of project-specific words - either hardcoded in `__DATA__`
or passed to `add_stopwords()` in every test file. This means:

- Every project carries its own hand-curated word list
- Common Perl jargon (`hashref`, `coderef`, `AUTOLOAD`) gets copied between projects
- Failures report the misspelled word but not **where** in the file it is

## The Solution

[**Test::Spelling::Stopwords**](https://metacpan.org/release/Test-Spelling-Stopwords)
solves this with two components that work together:

**1. `gen-stopwords`** - a companion CLI script that scans your project,
runs `aspell`, and writes a `.stopwords` file containing *only*
project-specific vocabulary - after filtering out the ~1000 common Perl
terms already covered by [**Pod::Wordlist**](https://metacpan.org/pod/Pod::Wordlist).

**2. `Test::Spelling::Stopwords`** - a test module that auto-discovers the
`.stopwords` file, loads it, and reports spelling failures with **exact line
numbers** so you can find and fix them immediately.

---

## Quick Start

### 1. Install

```bash
cpanm -vS Test::Spelling::Stopwords
```

This also installs the `gen-stopwords` script to your `$PATH` and `aspell`
must be available on your system (see [Requirements](#requirements)).

### 2. Generate your stopwords file

Run once from your project root:

```bash
gen-stopwords -v
```

This scans `lib/`, `bin/`, and `script/` by default, runs `aspell` on every
`.pm`, `.pl`, `.pod`, and `.t` file, filters out terms already in
`Pod::Wordlist`, and writes a lean `.stopwords` to your project root.

```
gen-stopwords v0.01
Language : en_GB
Output   : .stopwords
Dirs     : .
Loading Pod::Wordlist...
  978 word(s) loaded — these will be filtered from output.
Scanning source files...
  Processing: ./lib/My/Module.pm
  Processing: ./lib/My/Module/Helper.pm
Done. Scanned 8 file(s), skipped 1, filtered 47 already-known term(s).
Wrote 23 project-specific term(s) to .stopwords.
```

### 3. Create your spelling test

```perl
# xt/spell-pod.t
use Test::More;
use Test::Spelling::Stopwords;

unless ($ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING} || $ENV{CI}) {
    plan skip_all => 'Spelling tests only run under AUTHOR_TESTING';
}

all_pod_files_spelling_ok();
```

### 4. Run it

```bash
AUTHOR_TESTING=1 prove -lv xt/spell-pod.t
```

```
ok 1 - POD spelling: lib/My/Module.pm
ok 2 - POD spelling: lib/My/Module/Helper.pm
1..2
```

### 5. Regenerate when you edit source files

```bash
gen-stopwords
```

The test warns you automatically if you forget:

```
# ------------------------------------------------------------
# WARNING: .stopwords is out of date!
# Run gen-stopwords to regenerate it.
# ------------------------------------------------------------
```

---

## Why Not Just Use Test::Spelling?

[Test::Spelling](https://metacpan.org/pod/Test::Spelling) is excellent and
this module does not replace it. The gaps this module fills are:

| Feature | Test::Spelling | Test::Spelling::Stopwords |
|---|---|---|
| Spell-checks POD | ✅ | ✅ |
| Uses Pod::Wordlist | ✅ | ✅ (via gen-stopwords filter) |
| Auto-discovers `.stopwords` | ❌ | ✅ |
| Line-number reporting | ❌ | ✅ |
| Stopwords freshness warning | ❌ | ✅ |
| Companion generator script | ❌ | ✅ |
| Zero test file customisation | ❌ | ✅ |

The key practical difference: with `Test::Spelling` your test file must contain
project-specific word lists. With this module your test file is identical across
every project you maintain - all project-specific content lives in `.stopwords`
and is generated automatically.

---

## Detailed Usage

### Module API

#### `all_pod_files_spelling_ok`

The primary entry point. Finds all POD files, checks each one, emits one
TAP result per file.

```perl
# Zero config — uses defaults and .stopwords in project root
all_pod_files_spelling_ok();

# With per-call overrides
all_pod_files_spelling_ok(
    lang           => 'en_US',
    stopwords_file => 'xt/.stopwords',
    dirs           => ['lib', 'bin'],
);
```

When a file fails, every misspelled word is reported with its line numbers:

```
not ok 1 - POD spelling: lib/My/Module.pm
#   'serialiisable'  line(s): 42
#   'custmer'        line(s): 17, 83, 201
```

Skips gracefully (via `skip_all`) if `aspell` is absent, `.stopwords` does
not exist, or no POD files are found.

#### `pod_file_spelling_ok`

Check a single file. Useful when you want to select files yourself.

```perl
use Test::More tests => 1;
use Test::Spelling::Stopwords;

pod_file_spelling_ok('lib/My/Module.pm');

# With an explicit stopwords hash and custom test name
my %words = (dbic => 1, mojolicious => 1);
pod_file_spelling_ok('lib/My/Module.pm', \%words, 'Checking Module.pm');
```

#### Configuration functions

```perl
set_spell_lang('en_US');              # default: en_GB
set_stopwords_file('xt/.stopwords');  # default: .stopwords
set_spell_dirs('lib', 'bin');         # default: lib, bin, script
set_spell_dirs(['lib', 'bin']);       # arrayref form also accepted

my $path = get_stopwords_file();      # retrieve current path
```

### Environment Variables

All configuration can be overridden without editing any file:

| Variable | Default | Description |
|---|---|---|
| `SPELL_LANG` | `en_GB` | aspell language code |
| `STOPWORD_FILE` | `.stopwords` | Path to stopwords file |
| `SPELL_DIRS` | `lib:bin:script` | Colon/comma-separated scan dirs |
| `ASPELL_CMD` | `aspell list -l $LANG --run-together` | Full aspell command |

```bash
# Run with American English against a custom stopwords file
SPELL_LANG=en_US STOPWORD_FILE=xt/.stopwords AUTHOR_TESTING=1 prove xt/spell-pod.t
```

### The `gen-stopwords` Script

```
Usage: gen-stopwords [OPTIONS]

Options:
  -l, --lang LANG          aspell language code (default: en_GB)
  -o, --output FILE        output file path (default: .stopwords)
  -p, --pws FILE           personal aspell wordlist (default: ~/.aspell.en.pws)
  -d, --dir DIR            directory to scan; repeatable (default: .)
  -m, --min-len N          minimum word length to include (default: 2)
  -v, --verbose            print every file and every filtered word
  -q, --quiet              suppress all non-error output
  -n, --dry-run            preview output without writing
      --no-global          skip personal aspell wordlist
      --no-wordlist        skip Pod::Wordlist filtering
  -V, --version            print version and exit
  -h, --help               print this help and exit
```

**Common invocations:**

```bash
# Scan current directory (default)
gen-stopwords

# Scan specific directories
gen-stopwords --dir lib --dir bin --dir t

# Use American English
gen-stopwords --lang en_US

# Preview without writing anything
gen-stopwords --dry-run --verbose

# Compare output with and without Pod::Wordlist filtering
gen-stopwords --no-wordlist --output .stopwords-full
diff .stopwords-full .stopwords
```

### The `.stopwords` File Format

Plain text, one word per line, comments with `#`, blank lines ignored:

```
# Auto-generated stopwords for en_GB
# Generated by gen-stopwords v0.01 on Sun Mar  1 06:02:09 2026
# Contains only project-specific terms not covered by Pod::Wordlist.
# Do not edit manually — re-run gen-stopwords to regenerate.
async
dbic
mojolicious
myauthor
resultset
```

Commit this file to version control. It should be small - typically
`20–80 words` for a well-maintained project, covering only your module
names, domain terms, and author names.

---

## How POD Cleaning Works

Before a line is passed to `aspell`, all POD formatting codes are stripped
**entirely** - not expanded:

```
E<gt>           -> ""   (not "gt" - prevents the "Egt" false positive)
L<Some::Module> -> ""
C<$code>        -> ""
B<bold text>    -> ""
```

This is more aggressive than content extraction and eliminates an entire
class of false positives where POD entity fragments appear as bare words
in aspell output. The `--run-together` flag is always passed to aspell so
compound identifiers like `ResultSet` and `PendingChange` are handled
correctly.

---

## Two-Layer Stopword Architecture

```
┌─────────────────────────────────────────────────┐
│  Layer 1: Pod::Wordlist (~978 words)            │
│  hashref, coderef, AUTOLOAD, MERCHANTABILITY,   │
│  namespace, stringify, destructor, ...          │
│  Maintained by the CPAN community               │
└─────────────────────────────────────────────────┘
          gen-stopwords filters these out
┌─────────────────────────────────────────────────┐
│  Layer 2: .stopwords (your project's words)     │
│  dbic, mojolicious, resultset, myauthor, ...    │
│  Generated automatically, committed to git      │
└─────────────────────────────────────────────────┘
```

Words in `Layer 1` are owned by the CPAN community - you get improvements
for free when you upgrade `Pod::Wordlist`. Words in `Layer 2` are yours -
lean, meaningful, and specific to your project.

---

## Requirements

- **Perl** 5.14 or later
- **aspell** installed on the system and on `$PATH`
  - Debian/Ubuntu: `sudo apt-get install aspell aspell-en`
  - macOS (Homebrew): `brew install aspell`
  - Fedora/RHEL: `sudo dnf install aspell aspell-en`
- **CPAN modules** (installed automatically with `cpanm`):
  - [Test::Builder](https://metacpan.org/pod/Test::Builder) (core)
  - [File::Find](https://metacpan.org/pod/File::Find) (core)
  - [File::Spec](https://metacpan.org/pod/File::Spec) (core)
  - [Cwd](https://metacpan.org/pod/Cwd) (core)
  - [Pod::Wordlist](https://metacpan.org/pod/Pod::Wordlist) (recommended, used by `gen-stopwords`)

> **Note:** Windows is not currently supported due to the shell pipe to
> `aspell`. Patches are welcome.

---
