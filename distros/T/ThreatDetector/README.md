# ThreatDetector

**Modular Apache Log Threat Detection for Vicidial and Linux Web Servers**

ThreatDetector is a modular, extensible, Perl-based threat detection framework for parsing Apache logs. It detects web attacks such as SQL Injection, XSS, Command Injection, Directory Traversal, and more. Designed with call center infrastructures and Vicidial clusters in mind, it supports multi-host scanning via SSH and generates rich summary reports.

---

## Features

- Detects and classifies:
  - SQL Injection
  - Cross-Site Scripting (XSS)
  - Command Injection
  - Login Brute-Force
  - Directory Traversal
  - Encoded Payloads
  - HTTP Method Abuse
  - Suspicious Headers
  - Bot Fingerprints
  - 400–499 Client Errors
- Smart, pluggable classifier
- Per-host threat summary report
- Multi-host support via SSH (partial WIP under `utils`)
- Optional verbose colorized CLI output
- Designed to work with Vicidial environments out-of-the-box

---

## Requirements

- Perl 5.10 or later
- These CPAN modules:

```bash
cpan install JSON File::Slurp Getopt::Long Term::ANSIColor IPC::System::Simple
```

```bash
#!/usr/bin/perl

use strict;
use warnings;
use ThreatDetector;

my $log_file    = '/var/log/apache2/access.log';
my $config_file = '/etc/threatdetector/config.json';  # or wherever you placed it

ThreatDetector::analyze_log($log_file, $config_file);
```

## Project Structure

- `bin/`
  - `detect.pl` – Main scanner CLI
- `config/`
  - `config.json` – Log file path, output dir, verbosity
- `data/`
  - `ip_cache.sqlite` – (Optional future use)
- `lib/ThreatDetector/` – Classifier, dispatcher, handlers, reporter
- `logs/`
  - `YYYY-MM-DD_threat_results.log` – Output reports
- `t/`
  - `*.t` – Unit tests
- `utils/`
  - `add_shebang.pl` – Add missing shebangs
  - `check_deps.pl` – Verify/install required modules
  - `find_used_modules.pl` – Extract used modules for PREREQ_PM
  - `ssh_remote_runner.pl` – Remote SSH scanner (NOT COMPLETE)
- `Makefile.PL` – CPAN build script
- `MANIFEST` – Package contents
- `README.md` – This file

## Usage

```bash
perl bin/detect.pl --logfile /var/log/apache2/access.log
```

## Testing

```bash
prove -lv t/
```
