# Using Jev and TypeSafe System One with WebService::TypeSafe

This guide assumes basic Perl syntax but no prior experience with AI APIs.

`WebService::TypeSafe` is provided by Data Sculpting Inc.
(`info@datasculpting.com`, <https://datasculpting.com/>).

## 1. How the API works

A System One request contains `state` (the data to evaluate), `questions`
(named decisions Jev should make), and a `model` (normally `jev-latest`). Each
answer returns under the same name as its question. Asking several questions
in one request is the normal pattern.

## 2. Installation

The distribution requires Perl 5.20 or newer.

```sh
unzip WebService-TypeSafe-0.01.zip
cd WebService-TypeSafe-0.01
perl Makefile.PL
make
make test
make install
```

For a user-local installation:

```sh
perl Makefile.PL INSTALL_BASE="$HOME/perl5"
make
make test
make install
export PERL5LIB="$HOME/perl5/lib/perl5${PERL5LIB:+:$PERL5LIB}"
```

Run an example without installing with `perl -Ilib examples/basic.pl`.

## 3. Authentication

The primary interface is the `api_key` constructor option. Obtain the key from
your application's configuration or secret manager, then pass it explicitly:

```perl
my $api_key = get_typesafe_api_key_from_your_config();

my $client = WebService::TypeSafe->new(
    api_key => $api_key,
);
```

This makes the client's dependency explicit, supports multiple clients with
different credentials, and simplifies tests. Do not hard-code or commit the
actual key.

### Optional environment fallback

If `api_key` is omitted, the constructor falls back to `TYPESAFE_API_KEY`. This
is convenient for command-line programs, containers, and CI environments.

Linux or macOS:

```sh
export TYPESAFE_API_KEY='your-api-key'
```

In Windows PowerShell:

```powershell
$env:TYPESAFE_API_KEY = 'your-api-key'
```

With the fallback configured, this is equivalent:

```perl
my $client = WebService::TypeSafe->new;
```

An explicitly passed `api_key` always takes precedence over
`TYPESAFE_API_KEY`.

## 4. Your first request

```perl
use strict;
use warnings;
use feature 'say';
use WebService::TypeSafe qw(noul);

my $api_key = get_typesafe_api_key_from_your_config();
my $client = WebService::TypeSafe->new(api_key => $api_key);
my $result = $client->system_one(
    state => 'Help! My payouts have failed for three days.',
    questions => {
        urgent => noul(
            instructions => 'Does this message convey urgency?',
        ),
    },
);

my $probability = $result->answers->{urgent}->noul;
say "Probability of yes: $probability";
say 'Route to urgent queue' if $probability >= 0.8;
```

## 5. Choosing a question type

### Noul: yes or no

Use Noul when the probability of a true condition is useful.

```perl
my $question = noul(
    instructions => 'Does the customer explicitly request a refund?',
    criteria => {
        true  => 'The customer asks for money to be returned',
        false => 'No refund is requested',
    },
);

my $p_yes = $result->nouls->{refund_requested}->noul;
```

`criteria` is optional. Noul has no separate confidence: near 1 favors yes,
near 0 favors no, and near 0.5 is uncertain.

### Choice: one named alternative

Use Choice for unordered categories.

```perl
my $question = choice(
    instructions => 'Which team should handle this ticket?',
    criteria => {
        billing   => 'Invoices, charges, refunds, or payouts',
        technical => 'Bugs, outages, or integrations',
        sales     => 'Pricing, trials, or upgrades',
        other     => undef,
    },
);

my $answer = $result->choices->{department};
say $answer->choice;
say $answer->confidence;
say $answer->probabilities->{billing};
```

Include `other` if the list may not cover every input.

### Score: an ordered scale

Use Score for a spectrum with 2–10 defined levels.

```perl
my $question = score(
    instructions => 'How frustrated is the customer?',
    criteria => [
        'Calm and neutral',
        'Concerned but civil',
        'Angry or using strong language',
    ],
);

my $answer = $result->scores->{frustration};
say $answer->score;              # May fall between levels
say $answer->confidence;
say $answer->legend->{0};
say $answer->probabilities->{2};
```

## 6. Reading responses

Every answer is in `$result->answers->{question_name}` and is also grouped by
type in `$result->nouls`, `$result->choices`, or `$result->scores`.

```perl
say $result->model;
say $result->usage->input_tokens;
say $result->usage->output_tokens;

my $answer_hash = $result->answers->{urgent}->raw;
```

## 7. Structured state and instructions

State may be a string, hash reference, or array reference containing
JSON-compatible values.

```perl
my $state = {
    ticket => {
        subject => 'Duplicate charge',
        messages => [
            { from => 'customer', text => 'I was charged twice. Refund it.' },
            { from => 'support',  text => 'We are checking.' },
        ],
    },
    order => {
        id => 'A-104',
        charges => [
            { amount_usd => 49, status => 'captured' },
            { amount_usd => 49, status => 'captured' },
        ],
    },
};

my $result = $client->system_one(
    state => $state,
    questions => {
        refund_requested => noul(
            instructions => 'Does `ticket.messages[0].text` request a refund?',
        ),
        duplicate_charge => noul(
            instructions => 'Do `order.charges` show a duplicate charge?',
        ),
    },
);
```

Instructions and criteria may themselves be strings, hashes, or arrays.

## 8. Confidence-based routing

Choice and Score answers include confidence. Your code decides what is safe
enough for automatic action.

```perl
my $routing = $result->choices->{department};

if ($routing->confidence >= 0.85) {
    route_ticket($routing->choice);
}
else {
    send_to_human_review();
}
```

For Noul, use a review band:

```perl
my $p = $result->nouls->{safe_to_publish}->noul;
if    ($p >= 0.9) { publish() }
elsif ($p <= 0.1) { reject() }
else              { review() }
```

Tune thresholds using examples from your own application.

## 9. Client configuration

```perl
use WebService::TypeSafe qw(retry_policy);

my $client = WebService::TypeSafe->new(
    api_key  => $api_key,
    model    => 'jev-latest',
    base_url => 'https://api.typesafe.ai',
    timeout  => 30,
    retry    => retry_policy(max_retries => 3),
    headers  => { 'x-application-name' => 'support-router' },
);
```

The normal credential option is `api_key`. Its optional environment fallback
is `TYPESAFE_API_KEY`. The other environment defaults are
`TYPESAFE_DEFAULT_MODEL` and `TYPESAFE_BASE_URL`. Explicit constructor options
take precedence over all environment values. A request may override `model`,
`timeout`, `retry`, `extra_headers`, or `extra_body`.

```perl
my $result = $client->system_one(
    state => $state,
    questions => \%questions,
    timeout => 15,
    extra_headers => { 'x-trace-id' => $trace_id },
);
```

## 10. Retries and timeouts

By default, retryable failures receive two additional attempts with exponential
backoff. Numeric `Retry-After` and `retry-after-ms` headers are honored.

```perl
my $policy = retry_policy(
    max_retries     => 4,
    backoff_initial => 0.5,
    backoff_max     => 8,
    backoff_jitter  => 0.25,
    timeout         => 30,  # Total retry budget
);
```

Disable retries with `retry_policy(max_retries => 0)`. The client `timeout` is
the HTTP operation timeout; the policy `timeout` is the overall retry budget.

## 11. Error handling

Exceptions are objects, but unrelated Perl code can still throw strings, so
check `ref($@)` before calling methods.

```perl
my $result = eval {
    $client->system_one(state => $state, questions => \%questions);
};

if (my $error = $@) {
    if (ref($error) && $error->isa('WebService::TypeSafe::RateLimitError')) {
        warn 'Rate limited; request ID: ', ($error->request_id // 'unknown');
    }
    elsif (ref($error) && $error->isa('WebService::TypeSafe::AuthenticationError')) {
        die 'Check api_key or its TYPESAFE_API_KEY fallback';
    }
    elsif (ref($error) && $error->isa('WebService::TypeSafe::TimeoutError')) {
        warn 'Timed out after ', $error->timeout, ' seconds';
    }
    elsif (ref($error) && $error->isa('WebService::TypeSafe::APIError')) {
        warn 'HTTP status: ', $error->status;
        die $error;
    }
    else {
        die $error;
    }
}
```

Status-specific classes include `BadRequestError` (400),
`AuthenticationError` (401), `PermissionDeniedError` (403), `NotFoundError`
(404), `UnprocessableEntityError` (422), `RateLimitError` (429), and
`InternalServerError` (5xx), all under `WebService::TypeSafe::`. Connection, timeout,
and response-validation classes are also provided. API errors expose `status`,
`body`, `headers`, `endpoint`, and `request_id`.

## 12. Listing models

```perl
my $response = $client->models->list;
for my $model (@{ $response->models }) {
    say $model->name;
    say '  ', $model->description if defined $model->description;
}
```

Use `jev-latest` unless you intentionally need a pinned model version.

## 13. Testing without calling the API

Inject an HTTP coderef to capture requests and return fixtures without network
access or API charges:

```perl
use JSON::PP qw(encode_json);

my $client = WebService::TypeSafe->new(
    api_key => 'test-key',
    http => sub {
        my ($method, $url, $request) = @_;
        return {
            success => 1,
            status  => 200,
            headers => {},
            content => encode_json({
                model => 'jev-test',
                answers => {
                    urgent => { type => 'noul', noul => 0.95 },
                },
                usage => { input_tokens => 10, output_tokens => 2 },
            }),
        };
    },
);
```

See `t/02-client.t` and `t/03-errors-retries.t` for complete examples.

## 14. Common recipes

### Route a support ticket

```perl
my $result = $client->system_one(
    state => { message => $ticket_text },
    questions => {
        department => choice(
            instructions => 'Which department should handle `message`?',
            criteria => {
                billing => 'Invoices, charges, or refunds',
                technical => 'Bugs, outages, or integrations',
                sales => 'Pricing or upgrades',
                other => undef,
            },
        ),
        urgent => noul(
            instructions => 'Does `message` need immediate attention?',
        ),
    },
);

my $queue = $result->choices->{department}->choice;
my $priority = $result->nouls->{urgent}->noul >= 0.8 ? 'high' : 'normal';
enqueue($queue, $priority, $ticket_text);
```

### Batch decisions about one state

```perl
my %questions = (
    refund_requested => noul(instructions => 'Is a refund requested?'),
    contains_pii     => noul(instructions => 'Does the message contain PII?'),
    sentiment        => choice(
        instructions => 'What is the dominant sentiment?',
        criteria => { positive => undef, neutral => undef, negative => undef },
    ),
    severity => score(
        instructions => 'How severe is the reported problem?',
        criteria => ['Minor', 'Moderate', 'Major', 'Critical'],
    ),
);

my $result = $client->system_one(
    state => $message,
    questions => \%questions,
);
```

Question helpers are optional; raw hashes also work:

```perl
questions => {
    urgent => { type => 'noul', instructions => 'Is this urgent?' },
}
```

## 15. Troubleshooting

### `Can't locate TypeSafe/SDK.pm in @INC`

The SDK is not installed or Perl cannot see it. From the unpacked project, run
`perl -Ilib your_script.pl`. Check `PERL5LIB` after a user-local installation.

### `TypeSafe API key is required`

Pass a nonempty `api_key` to `WebService::TypeSafe->new`. If you intentionally
use the environment fallback, set `TYPESAFE_API_KEY` in the same shell that
starts Perl. Check its presence without printing the secret:

```sh
perl -e 'print $ENV{TYPESAFE_API_KEY} ? "key is set\n" : "key is missing\n"'
```

### HTTP 401

The key is invalid or expired. Update it and restart the process so it receives
the new environment.

### HTTP 422

Check question types and criteria. Choice needs a nonempty hash; Score needs
2–10 levels. The exception's `body` contains server validation details.

### HTTP 429 or 529

The service is rate-limited or overloaded. Default retries handle these
statuses. If failures continue, reduce concurrency or increase the retry budget.

### Uncertain results

Make instructions and criteria more distinct, include the relevant state, and
route low-confidence answers for human review.

## Further help

After installation, run `perldoc WebService::TypeSafe`. TypeSafe's public
documentation is at <https://docs.typesafe.ai/>.
