# WebService::SmsGora

[![tests](https://github.com/TekservixHQ/smsgora-perl/actions/workflows/tests.yml/badge.svg)](https://github.com/TekservixHQ/smsgora-perl/actions/workflows/tests.yml)

Perl client for the [SMS Gora SMS Gateway](https://tekservix.com/smsgora/) API.

SMS Gora turns Android phones with ordinary SIM cards into an SMS gateway. Your server calls the API, a linked phone sends the text, and replies and delivery reports come back to you. There's no sender ID registration and no per-message fee from us: your mobile operator bills the texts like any SMS.

- Perl 5.10+, core modules only (HTTP::Tiny, JSON::PP, Digest::SHA); HTTPS needs IO::Socket::SSL
- Works in Mojolicious, Dancer2, Catalyst, CGI scripts and cron jobs
- Webhook signature check built in

## Install

```bash
cpanm WebService::SmsGora
```

## Quick start

You need a Tekservix account with SMS Gora and an API key (SMS Gora → API keys). Keep it on your server.

```perl
use WebService::SmsGora;

my $sms = WebService::SmsGora->new(api_key => $ENV{SMSGORA_KEY});

my $result = $sms->send_sms(to => '+15551234567', message => 'Your verification code is 482913');
print "Queued: @{ $result->{message_ids} }\n";
```

## Sending

```perl
# Several recipients (up to 1,000 per call)
$sms->send_sms(to => ['+15551234567', '+447700900123'], message => 'Your order has shipped');

# From a chosen phone and SIM, scheduled for later
$sms->send_sms(
    to          => '+15551234567',
    message     => 'Reminder: your appointment is tomorrow at 10:00',
    device_id   => 42,
    sim_slot    => 1,                        # 0 = SIM 1, 1 = SIM 2
    schedule_at => '2026-12-01T08:00:00Z',
);

# Different texts for different people in one call (up to 5,000 recipients)
$sms->send_bulk_sms(42,
    message_template => 'Hello, your parcel is ready for pickup.',
    messages => [
        { recipients => ['+15551234567'], message => 'Hi Aline, parcel #1042 is ready.' },
        { recipients => ['+15557654321'] },
    ],
);
```

## Delivery status and incoming SMS

```perl
my $msg = $sms->get_message(1873);
print $msg->{status};                       # queued -> dispatched -> sent -> delivered

$sms->cancel_message(1874);                 # works while queued or scheduled

my $inbox   = $sms->list_received_sms(since => '2026-11-01', limit => 50);
my $phones  = $sms->list_devices;
my $account = $sms->get_account;

my $batch = $sms->request(GET => '/batches/311');   # any other endpoint
```

## Webhooks

Add your HTTPS URL in SMS Gora → Webhooks (or with `create_webhook`) and keep the secret. Each request carries `X-SmsGora-Signature: sha256=...`, an HMAC-SHA256 of the raw body. Mojolicious example:

```perl
post '/sms-webhook' => sub {
    my $c   = shift;
    my $raw = $c->req->body;
    return $c->render(text => 'bad signature', status => 401)
        unless WebService::SmsGora::verify_webhook($raw, $c->req->headers->header('X-SmsGora-Signature'), $ENV{SMSGORA_WEBHOOK_SECRET});

    my $event = $c->req->json;
    if ($event->{event} eq 'sms.received') {
        # $event->{data}{from}, $event->{data}{message}
    }
    $c->render(text => 'ok');   # answer within 10 seconds
};
```

## Errors

Failed calls die with a `WebService::SmsGora::Error` that has `status`, `message`, `errors` and `retry_after` (seconds, on 429):

```perl
use Scalar::Util qw(blessed);

eval { $sms->send_sms(to => '+15551234567', message => 'Hi'); 1 } or do {
    my $e = $@;
    die $e unless blessed $e && $e->isa('WebService::SmsGora::Error');
    sleep($e->retry_after // 5) if $e->status == 429;
};
```

## More from Tekservix

- [WAservix WhatsApp API Gateway](https://tekservix.com/waservix/): WhatsApp from your own number (`cpanm WebService::WAservix`)
- [AI Sales Agent](https://tekservix.com/ai-sales-agent): answers customers on WhatsApp and SMS using your website's content
- [Website to App](https://tekservix.com/mobile-apps): turn your website into Android and iOS apps
- SMS Gora is also available for Node.js, Python, PHP, Go, Java/Kotlin, .NET, Ruby, Swift, Rust, Dart, Deno, Elixir, n8n and Node-RED: [github.com/TekservixHQ](https://github.com/TekservixHQ)

## License

MIT
