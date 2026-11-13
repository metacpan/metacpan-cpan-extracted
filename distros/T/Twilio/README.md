# Twilio for Perl

[![CI](https://github.com/Zarabozo/Twilio/actions/workflows/ci.yml/badge.svg)](https://github.com/Zarabozo/Twilio/actions/workflows/ci.yml)

A Perl library for the [Twilio](https://www.twilio.com/) API. It sends messages,
makes and answers calls, and reaches Twilio's other products the same way as
Twilio's official libraries for PHP, Python and Node.js, so Twilio's own
documentation applies to it.

Version 2 is a complete rewrite and shares no code with version 1.

## Installation

```sh
cpanm Twilio
```

It needs Perl 5.16 or later. Two modules are optional: `Cpanel::JSON::XS` makes
JSON faster, and `Crypt::OpenSSL::RSA` is needed only for Public Key Client
Validation.

## Quick start

Send an SMS:

```perl
use Twilio;

my $client = Twilio->new;    # reads TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN

my $message = $client->messages->create('+15558675310', {
  from => '+15017122661',
  body => 'Hello from Perl',
});
print $message->sid, "\n";
```

Make a call:

```perl
my $call = $client->calls->create('+15558675310', '+15017122661', {
  url => 'http://demo.twilio.com/docs/voice.xml',
});
```

Reply to an incoming SMS, from the webhook of your Twilio number (a CGI script
here; [Twilio::Manual](https://metacpan.org/pod/Twilio::Manual) also shows
Mojolicious):

```perl
use CGI;
use Twilio::TwiML::MessagingResponse;

my $query    = CGI->new;
my $response = Twilio::TwiML::MessagingResponse->new;
$response->message('Thanks! You said: ' . $query->param('Body'));

print $query->header(-type => 'text/xml', -charset => 'UTF-8'), $response;
```

[Twilio::Manual](https://metacpan.org/pod/Twilio::Manual) is the guide: it
follows Twilio's messaging and voice quickstarts, and covers credentials, API
keys, webhook validation, lists, errors, other products, and how to translate
any example from Twilio's documentation.

## What it covers

- **The REST API of Twilio's products**: 58 API versions and 577 resources,
  generated from Twilio's OpenAPI specifications, from Messaging, Voice and
  Verify to Conversations, Studio, TaskRouter, Flex, Sync and Lookups. Each
  resource is documented with every value it takes, in Twilio's words.
- **TwiML** for voice, messaging and fax, with every verb and attribute.
- **Webhook validation** of Twilio's signatures, for form and JSON requests, and
  for webhooks signed with a shared key.
- **Access tokens** for Twilio's client SDKs, and the older capability tokens.
- **Authentication** with the Auth Token, API keys, OAuth client credentials, and
  Public Key Client Validation.
- Regions and edges, retries after HTTP 429, paging of both kinds Twilio uses,
  file uploads, detailed errors (including RFC 9457), and the status code and
  headers of each answer.

## How it follows the official libraries

The library has the same structure as Twilio's official libraries, which are
generated from the same specifications: a client, then a product and version,
then a resource's list, a record's context, and the record itself.

```perl
$client->verify->v2->services($service_sid)->verifications->create('+15558675310', 'sms');
```

is, step by step, the same chain as in PHP, Python or Node.js. Where the
libraries differ, it follows twilio-php: method names, the order of required
values, paging, and the format of errors and TwiML. So a documentation example
translates with a few rules: names in snake_case, required values first as plain
arguments, optional values in a hash reference, and `eval` for errors. The
manual lists them all, with examples.

## How it is built

The 678 modules under `Twilio::Rest` are generated, as the official libraries'
are. The generator in `tools/` reads Twilio's OpenAPI specifications (`twilio-oai`, pinned
to a release) and applies the rules of Twilio's own generator, deciding unclear
cases the way twilio-php 8.14 does. Each class gets its documentation from the
descriptions in the specifications. The TwiML classes are generated from the
element and attribute names in twilio-php.

The rest is written by hand: HTTP, authentication, paging, errors, TwiML
writing, tokens and validation. It is ported from twilio-php, with choices from
twilio-python and twilio-node where those are better, such as keeping an OAuth
token for each credential provider, as twilio-python does. Only requests that
Twilio refused with HTTP 429 are ever sent again, so a message is never sent
twice.

The generated code is committed, and an author test fails if it differs from what
the generator writes. The generator is not part of the CPAN distribution; see
[tools/README.md](tools/README.md).

## How it is tested

- **Unit tests** cover every hand-written module, with a fake HTTP client, so
  they need no account and no network.
- **Vectors from real twilio-php**: access tokens, capability tokens, webhook
  signatures and TwiML are compared with what twilio-php itself produces.
- **Contract tests** check each of the 1,563 operations against its
  specification: the URL, the method, the names and formats of the values, and
  the reading of every documented answer.
- **The official libraries' tests**: the hand-written tests of twilio-php 8.14,
  twilio-python 9.13 and twilio-node 6.3 were compared case by case with these,
  and the missing cases added.
- **Live tests**, which you can turn on, call the real API: read-only by default,
  and with a second switch, checks that create free resources and delete them.
- **Every example in the manual** is run by the tests, so the documentation
  can't drift from the code.
- **CI** runs on Linux, macOS and Windows, with Perl 5.16 and the latest Perl,
  plus Perl::Critic, perltidy, POD coverage and a full distribution check.

## Development

```sh
perl Makefile.PL
make test        # nmake on Windows with MSVC
```

Author checks are in `xt/`, and need the `develop` prerequisites listed in
`Makefile.PL`:

```sh
prove -lr xt
```

The live tests need a Twilio account; `xt/live/smoke.t` explains its switches.

## Issues and contributions

Bug reports and pull requests are welcome through
[GitHub issues](https://github.com/Zarabozo/Twilio/issues).
[CONTRIBUTING.md](CONTRIBUTING.md) explains how to work on the library.

Report security problems privately, by email, as [SECURITY.md](SECURITY.md)
explains, not through issues.

## License

[MIT](LICENSE). This is an independent project. It is not written, endorsed or
supported by Twilio Inc., and "Twilio" is a trademark of Twilio Inc.

Parts of it are based on Twilio's own MIT-licensed work, twilio-php and the
twilio-oai specifications. As that license requires, [LICENSE](LICENSE) also
includes Twilio's copyright notice for them, as credit.
