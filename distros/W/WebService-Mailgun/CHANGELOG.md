# Changelog

All notable changes to WebService-Mailgun are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions up to 0.17 were released from `Changes`, before this file existed.

## [Unreleased]

## [1.0.0] - 2026-11-09

- Version numbers have three parts from 1.0.0 on (`1.0.1`, `1.1.0`), and the change log moves from `Changes` to `CHANGELOG.md` (#16)
- Remove a contributor's e-mail address from the distribution metadata (`x_contributors` in `META.json` / `META.yml`) (#14)
- Stop shipping `cpanfile.snapshot` in the distribution: it pinned the dependencies to versions from 2021, and neither `cpanm` nor CPAN clients read it
- **Breaking:** Require Perl 5.20 or later (`use 5.020`). In 0.17 the module declared 5.8.1 and `META.json` 5.10, and CI tested neither; CI now tests 5.20 and 5.42
- Fix `event($url)`: since 0.07 it ignored the URL it was given (such as the second value an earlier `event()` returned) and fetched the first page of every event again. It now fetches the URL, which can be a `URI` or a string, and dies unless it is an https URL on the API's host, so that the API key is not sent anywhere else
- **Breaking:** The second value of `event()`, `lists()` and `list_members()` is the `paging.next` URL of the empty page they stop at, instead of its `paging.previous`. Passed back to `event()`, it returns only the events stored since, where the previous URL returned the last page again (up to `limit` events seen already). When a request fails, it is the URL of the page that failed, to fetch the rest from (#25)
- Fix the documentation: the `mime()` examples called `message()`, `lists()` / `list_members()` were taken in scalar context, `delete_list_member()` was named `delete_list_members()`, and the links to the Mailgun documentation were broken. Document how errors are returned, the two values of the methods that return every page, and attachments with an array reference

## [0.17] - 2026-08-03

- Get the Mailgun credentials for tests from environment variables (`MAILGUN_API_KEY`, `MAILGUN_DOMAIN`, `MAILGUN_TO`). The tests are skipped when they are not set
- Migrate CI from Travis CI to GitHub Actions

## [0.16] - 2023-09-12

- Fix document

## [0.15] - 2022-05-08

- Support partial template (thanks bjornjac)
- Fix https test (thanks eserte)

## [0.14] - 2022-01-18

- Support API region (thanks bjornjac)

## [0.13] - 2021-11-22

- Use JSON (thanks justingit)

## [0.12] - 2021-10-19

- Add MIME support (thanks justingit)

## [0.11] - 2021-08-02

- Fix parsing previous URL

## [0.10] - 2020-10-02

- Fix `message()` to support both HashRef and ArrayRef

## [0.09] - 2020-10-02

- Support sending attachment files
- Fix some test cases
- Update document

## [0.08] - 2020-02-24

- Fix event test

## [0.07] - 2019-12-27

- Fix event method
- Fix version format
- Update document

## [0.06] - 2017-03-02

- Fix recursive fetch data
- Support event recursive fetch
- Add `get_message_from_event`
- Update document

## [0.05] - 2017-03-01

- Support Event API

## [0.04] - 2016-08-27

- Fix cpanfile (add Try::Tiny)

## [0.03] - 2016-08-27

- Fix the behavior at the time of error
- Add RaiseError option
- Add `error`, `error_status` method
- Fix error message (use carp and croak)

## [0.02] - 2016-08-13

- Fix unit test
- Require perl 5.10 and later

## [0.01] - 2016-08-12

- Original version

[1.0.0]: https://github.com/kan/p5-web-service-mailgun/releases/tag/v1.0.0
[0.17]: https://metacpan.org/release/MIKIHOSHI/WebService-Mailgun-0.17
[0.16]: https://metacpan.org/release/MIKIHOSHI/WebService-Mailgun-0.16
[0.15]: https://metacpan.org/release/MIKIHOSHI/WebService-Mailgun-0.15
[0.14]: https://metacpan.org/release/MIKIHOSHI/WebService-Mailgun-0.14
[0.13]: https://metacpan.org/release/MIKIHOSHI/WebService-Mailgun-0.13
[0.12]: https://metacpan.org/release/MIKIHOSHI/WebService-Mailgun-0.12
[0.11]: https://metacpan.org/release/MIKIHOSHI/WebService-Mailgun-0.11
[0.10]: https://metacpan.org/release/MIKIHOSHI/WebService-Mailgun-0.10
[0.09]: https://metacpan.org/release/MIKIHOSHI/WebService-Mailgun-0.09
[0.08]: https://metacpan.org/release/MIKIHOSHI/WebService-Mailgun-0.08
[0.07]: https://metacpan.org/release/MIKIHOSHI/WebService-Mailgun-0.07
[0.06]: https://metacpan.org/release/MIKIHOSHI/WebService-Mailgun-0.06
[0.05]: https://metacpan.org/release/MIKIHOSHI/WebService-Mailgun-0.05
[0.04]: https://metacpan.org/release/MIKIHOSHI/WebService-Mailgun-0.04
[0.03]: https://metacpan.org/release/MIKIHOSHI/WebService-Mailgun-0.03
[0.02]: https://metacpan.org/release/MIKIHOSHI/WebService-Mailgun-0.02
[0.01]: https://metacpan.org/release/MIKIHOSHI/WebService-Mailgun-0.01
