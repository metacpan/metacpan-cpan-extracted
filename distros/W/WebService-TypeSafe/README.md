# WebService::TypeSafe

An unofficial synchronous Perl SDK for TypeSafe AI's System One API and Jev
models. It follows the public API and the shape of TypeSafe's official Python
and JavaScript SDKs, while using familiar Perl conventions.

Provided by **Data Sculpting Inc.**  
Email: **info@datasculpting.com**  
Website: **https://datasculpting.com/**

If you are new to this package, start with
[`docs/PERL-GUID.md`](docs/PERL-GUID.md). It explains the complete workflow,
from installing Perl through handling production errors.

## Five-minute start

### 1. Install

```sh
unzip WebService-TypeSafe-0.01.zip
cd WebService-TypeSafe-0.01
perl Makefile.PL
make
make test
make install
```

The SDK requires Perl 5.20 or newer and uses only modules distributed with
Perl.

### 2. Pass your API key to the client

The primary interface is the `api_key` constructor option. Obtain the value
from your application's configuration or secret manager and pass it when the
client is created:

```perl
my $api_key = get_typesafe_api_key_from_your_config();

my $client = WebService::TypeSafe->new(
    api_key => $api_key,
);
```

Do not hard-code or commit the actual key. As an optional convenience, the
client falls back to `TYPESAFE_API_KEY` when `api_key` is omitted:

```sh
export TYPESAFE_API_KEY='your-api-key'       # Linux or macOS
```

```powershell
$env:TYPESAFE_API_KEY = 'your-api-key'       # Windows PowerShell
```

```perl
my $client = WebService::TypeSafe->new;      # Uses the environment fallback
```

### 3. Make a decision

Save this as `ticket.pl`:

```perl
use strict;
use warnings;
use feature 'say';
use WebService::TypeSafe qw(choice noul score);

my $api_key = get_typesafe_api_key_from_your_config();
my $client = WebService::TypeSafe->new(api_key => $api_key);
my $result = $client->system_one(
    state => { message => 'My payout has failed for three days. Please help now!' },
    questions => {
        urgent => noul(instructions => 'Does `message` convey urgency?'),
        team => choice(
            instructions => 'Which team should handle `message`?',
            criteria => {
                billing   => 'Payments, invoices, payouts, or refunds',
                technical => 'Bugs, outages, or integrations',
                other     => undef,
            },
        ),
        frustration => score(
            instructions => 'How frustrated is the customer in `message`?',
            criteria => ['Calm', 'Concerned', 'Very angry'],
        ),
    },
);

say 'Urgent probability: ', $result->nouls->{urgent}->noul;
say 'Team: ',               $result->choices->{team}->choice;
say 'Frustration score: ',  $result->scores->{frustration}->score;
```

Run it with `perl ticket.pl`.

## Main interface

```perl
use WebService::TypeSafe qw(choice noul score retry_policy);

my $client = WebService::TypeSafe->new(
    api_key => $api_key,
    model   => 'jev-latest',
    timeout => 60,
    retry   => retry_policy(max_retries => 3),
);
```

The client supports:

- `$client->system_one(...)` to evaluate state against typed questions.
- `$client->models->list` to list models available to your account.
- `noul(...)` for a yes/no probability.
- `choice(...)` for one result from named alternatives.
- `score(...)` for a position on an ordered rubric.
- Typed collections at `$result->nouls`, `$result->choices`, and
  `$result->scores`, plus every answer at `$result->answers`.

## Configuration

| Constructor option | Environment variable | Default |
| --- | --- | --- |
| `api_key` | `TYPESAFE_API_KEY` | Required |
| `model` | `TYPESAFE_DEFAULT_MODEL` | `jev-latest` |
| `base_url` | `TYPESAFE_BASE_URL` | `https://api.typesafe.ai` |
| `timeout` | — | 60 seconds |
| `retry` | — | Two retries with exponential backoff |

Pass `api_key` explicitly for normal application use. If it is omitted, the
client tries `TYPESAFE_API_KEY`. Explicit constructor options always take
precedence over environment variables.

## Documentation included

- [`docs/PERL-GUID.md`](docs/PERL-GUID.md): full usage guide and recipes.
- [`examples/basic.pl`](examples/basic.pl): executable example.
- Embedded POD: run `perldoc WebService::TypeSafe` after installation.
- `t/`: examples of transport injection, retries, errors, and typed results.

## Compatibility and status

This project is community-created and is not an official TypeSafe AI package.
Its wire format follows TypeSafe's public System One API. The included tests use
an injected HTTP transport and do not consume API credits.

## License

Copyright (c) 2026 Data Sculpting Inc. Released under the MIT License.
