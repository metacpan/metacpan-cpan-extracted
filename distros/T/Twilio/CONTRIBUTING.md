# Contributing to Twilio for Perl

Bug reports, ideas and pull requests are welcome, through
[GitHub](https://github.com/Zarabozo/Twilio/issues). For a security problem,
don't open an issue: follow [SECURITY.md](SECURITY.md).

## Reporting a bug

Say which version of Twilio and of Perl you use, and on which system. Include
the smallest code that shows the problem, what you expected, and what happened,
with the full error. Leave out your credentials: an Auth Token or API secret
must never appear in an issue, even an expired one.

If the problem is in an answer from Twilio, the status code and headers help:
`with_metadata` gives them (see `Twilio::Metadata`).

## Before you start on a change

For anything bigger than a small fix, open an issue first, so we can agree on
the approach before you spend time on it. The library follows Twilio's official
libraries, and twilio-php where they differ, so a change that departs from them
needs a good reason.

## Setting up

```sh
git clone https://github.com/Zarabozo/Twilio.git
cd Twilio
perl Makefile.PL
make test          # nmake or gmake on Windows
```

It needs Perl 5.16 or later. The tests need no account and no network.

## Checks a pull request must pass

CI runs these on Linux, macOS and Windows, with Perl 5.16 and the latest Perl:

- `prove -lr t`: the tests.
- `prove -lr xt`: the author checks. They need the `develop` prerequisites in
  `Makefile.PL`: Perl::Critic, Test::Pod, Test::Pod::Coverage, and Perl::Tidy at
  exactly the version listed there, because each release of perltidy formats
  code a little differently.

Add a test for each change in behaviour, and documentation for each new method
or option. Code follows `.perltidyrc`, and `xt/author/tidy.t` fails when perltidy
would change a file. Comments explain why, not what the code does.

## Generated code

The modules under `lib/Twilio/Rest` and the TwiML classes are generated. Don't
edit them by hand: `xt/generator/up-to-date.t` fails when they differ from what
the generator writes. Change the generator in `tools/` instead, then run:

```sh
perl tools/fetch-specs.pl    # downloads Twilio's specifications into spec/
perl tools/generate.pl       # writes lib/ and t/data/
```

and commit the generator change and the files it writes. [tools/README.md](tools/README.md)
explains how the generator works.

## Live tests

`xt/live/smoke.t` calls the real API, and skips unless you turn it on. Its
header explains the switches. By default it only reads; `TWILIO_LIVE_WRITES=1`
adds checks that create free resources and delete them. Use a test or
sub-account, never your production credentials.

## Commits and pull requests

Keep each pull request to one change. Commit messages follow
[Conventional Commits](https://www.conventionalcommits.org/): `fix:`, `feat:`,
`docs:`, `test:`, `refactor:` and so on. Add a line to `Changes` under
`{{NEXT}}` for anything a user would notice.

By contributing, you agree that your work is released under the
[MIT License](LICENSE), like the rest of the library.
