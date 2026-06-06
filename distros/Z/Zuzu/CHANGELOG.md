# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project roughly adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html),
but using Perlish version numbers like `x.yyyzzz` instead of `x.y.z`.

## 0.001005 - 2026-06-05

### Changed

- Updated the `docs/userguide` and `languagetests` submodules.

### Fixed

- Fixed string indexing to return one-character strings, including negative
  indexes.
- Added BinaryString index and slice assignment support.

## 0.001004 - 2026-06-05

### Changed

- Raised the required versions of Path::Tiny and Sub::Quote.
- Marked the std/clib integration test as author-only.
- Excluded `blib` from distribution manifests.

### Fixed

- Fixed the marshal golden fixture test to parse on older supported Perl versions.

## 0.001003 - 2026-05-31

### Changed

- Bumped required version of CryptX.

## 0.001002 - 2026-05-29

### Changed

- Skipped some tests which should be author-only, using the AUTHOR_TESTING environment variable.

### Fixed

- Fixed various test cases that were based on outdated assumptions.

## 0.001001 - 2026-05-29

### Removed

- Remove redundant testing-related files from `t/` where there are newer version in `stdlib/`.
- Remove the outdated Zuzuzoo and Zuzuzoo::CLI modules.

## 0.001000 - 2026-05-29

*First release.*
