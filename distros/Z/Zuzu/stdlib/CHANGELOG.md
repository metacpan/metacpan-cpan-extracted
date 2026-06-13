# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Unreleased

### Fixed

- `std/math/bignum` tests now define `BigNum.to_dec` and
  `BigNum.to_String` as String-returning APIs, leaving `BigNum.to_Number`
  as the numeric conversion API.
