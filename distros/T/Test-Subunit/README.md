# Subunit for Perl

This repository contains basic Perl bindings for Subunit, as well as several
command-line tools.

## Protocols

Both the v1 (line-oriented text) and v2 (binary) protocols are supported.
See `Test::Subunit` for v1 emit/parse helpers and `Test::Subunit::V2` for v2.
`parse_results` auto-detects v2 by the `0xB3` signature byte.

## License

Apachev2 or later

## More information

See the main [Subunit homepage](https://github.com/testing-cabal/subunit) for
details. IRC Channel: #testing-cabal on [irc.libera.chat](https://libera.chat)
