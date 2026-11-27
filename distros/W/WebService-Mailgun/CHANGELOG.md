# Changelog

All notable changes to WebService-Mailgun are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions up to 0.17 were released from `Changes`, before this file existed.

## [Unreleased]

## [1.2.0] - 2026-11-26

- Document that Mailgun has deprecated the Events API of `event()` in favor of the Logs API, and point the TODO list at the successors of the deprecated Stats and Tags APIs (Metrics and the new Tags) (#48)
- Add the webhooks of the domain (the v3 API): `domain_webhooks()`, `domain_webhook()`, `add_domain_webhook()`, `update_domain_webhook()` and `delete_domain_webhook()` (#46)
- Add the suppressions of the domain: the bounces (`bounces()`, `bounce()`, `add_bounce()`, `add_bounces()`, `import_bounces()`, `delete_bounce()` and `delete_bounces()`), the unsubscribes and the complaints in methods of the same names, and the allowlist (`allowlist_entries()`, `allowlist_entry()`, `add_allowlist_entry()`, `import_allowlist()`, `delete_allowlist_entry()` and `delete_allowlist()`). `add_bounces()` sends `code` as a JSON string, even one given as a number, as Mailgun takes it, and `delete_unsubscribe()` takes an optional tag, to remove only that tag of the unsubscribe. The documentation of the imports gives the header row each kind needs (#44)
- Add the rest of the templates of the domain: `templates()`, `template()`, `update_template()`, `rename_template()`, `copy_template()`, and the versions (`template_versions()`, `template_version()`, `add_template_version()`, `update_template_version()`, `delete_template_version()` and `copy_template_version()`). `add_template()` sends a decoded string (one with the UTF-8 flag) encoded in UTF-8, as `message()` does; one with a character above `0xFF` used to die. HTTP::Request::Common 6.07 or later is required, for the form of a PUT (#45)
- Add the domains of the account (`domains()`, `get_domain()`, `add_domain()`, `update_domain()`, `verify_domain()` and `delete_domain()`) and the validation of an address (`validate_address()`). They call the v4 API on the host of the region; with `$API_BASE` (or `$API_BASE_EU`, `$API_BASE_AU`) replaced, on its host, with the `/v3` at its end replaced (#47)
- Add the analytics of the v1 API, the successors of the deprecated Events, Stats and Tags APIs: `logs()`, `metrics()`, `usage_metrics()`, `tags()`, `update_tag()`, `delete_tag()` and `tag_limits()`. Each sends the JSON body Mailgun documents and returns one page; `all_logs()` returns every page of the logs, following `pagination.next`. Furl 3.08 or later is required, for the body of a DELETE (#48)

## [1.1.0] - 2026-11-22

- Fix the methods that take a mailing list address, a member address or a template name: the value went into the URL path as it was, so one with `?`, `#`, `/` or `%` (all allowed in an e-mail address) sent the request to another URL. Such characters are now percent-encoded; `@`, `+` and the others a path segment can hold go out as before. Pass the address as it is: one already percent-encoded is encoded again. A missing (undefined or empty) address or name now dies instead of asking for another URL, such as `list(undef)` for every list (#34)
- Fix the methods dying without `RaiseError` on a response they did not expect: a failure whose body was JSON but not an object, a success whose body was not a JSON object, and a page of `lists()` / `list_members()` / `event()` without its list of items or without `paging.next`. Each of the first three is now a failure like any other (`error` and `error_status` are set, and it dies only with `RaiseError`), and a page without items gives its URL as the second value, as a failed request does. A page without `paging.next` is taken as the last one, and the second value is its own URL (never `undef`, which `event()` would take as a query for every event). A `paging.next` that points back to a page already fetched stops there as a failure, instead of going round for ever. A success with an empty body (`204 No Content`) returns an empty hash reference (#35)
- `message()` takes several values of a key in an array reference, such as `to => ['a@example.com', 'b@example.com']` or `'o:tag' => [...]`, and sends the key once for each. It used to die, taking the array reference for a file and opening a file named after the first address. Under `attachment` and `inline`, an array reference is still a file, and an array reference of those is several files. An empty array reference dies instead of leaving the key out (#36)
- Add the AU region: `region => 'au'` sends the requests to `api.au.mailgun.net` (#37)
- **Breaking:** The second value of `event()`, `lists()` and `list_members()` no longer carries the API key, so that it can be kept (for Event Polling) or logged without the key. Passing it back to `event()` works as before: `event()` sets the key. Code that took the key out of that URL, or fetched it with another client, has to set the key itself. A `paging.next` that is not an https URL on the API's host is now a failure rather than a URL the key is sent to, as for `event($url)`, and the message of `event($url)` refusing a URL no longer shows its API key (#38)
- `mime()` no longer changes the hash reference it is given, so the same one can be passed again; the second call used to send a broken message (`message`) or none (`file`). A MIME message given as a string goes in the request from memory, with no temporary file. Like `message()`, it takes several values of a key in an array reference (`to => [...]`). Giving both `message` and `file` dies, instead of sending the path of `file` as a field (#39)
- `message()` and `mime()` send a decoded string (one with the UTF-8 flag) encoded in UTF-8. One with a character above `0xFF` used to die in HTTP::Request::Common, and one with only characters below `0x100` went out in Latin-1. A string of bytes is sent as it is (#39)
- Add `timeout` to `new()`: the seconds a request may take, given to Furl (its default is 10), for large attachments over a slow connection (#40)
- `lists()` and `list_members()` take an optional hash reference of the query, such as `limit`, and `subscribed` for the members. A key of the query that `paging.next` leaves out is put back on the later pages, so that they are filtered the same way. Anything but a hash reference there now dies; it used to be ignored (#41)
- `get_message_from_event()` sends the API key only to an https URL on `mailgun.net` or a host under it, as `event($url)` does for the API's host; any other `storage.url` (of an event kept and read back, say) dies. It takes any event that has `storage.url`, not only a `stored` one. The message it dies with for an event without `storage.url` changes to "invalid event! this method needs an event with storage.url ..." (#42)
- Add `error_response`: the response (a Furl::Response) of the last request that failed, for its headers, such as `X-RateLimit-Reset` of a `429 Too Many Requests`. It does not keep the request, whose URL carries the API key. The documentation has a section on rate limits; the module still does not try again by itself (#43)
- Do not list the bots that commit to the repository (github-actions for the release pull requests, Dependabot) as contributors in the distribution metadata (`x_contributors`); 1.0.0 listed github-actions

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

[1.2.0]: https://github.com/kan/p5-web-service-mailgun/releases/tag/v1.2.0
[1.1.0]: https://github.com/kan/p5-web-service-mailgun/releases/tag/v1.1.0
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
