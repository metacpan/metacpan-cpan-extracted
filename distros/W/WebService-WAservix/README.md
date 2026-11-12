# WebService::WAservix

[![tests](https://github.com/TekservixHQ/waservix-perl/actions/workflows/tests.yml/badge.svg)](https://github.com/TekservixHQ/waservix-perl/actions/workflows/tests.yml)

**WAservix WhatsApp API Gateway** - official Perl client (WebService::WAservix): send WhatsApp messages from your own number. By Tekservix.

Perl client for the [WAservix WhatsApp API Gateway](https://tekservix.com/waservix/).

WAservix links your own WhatsApp number by QR code (the same way WhatsApp Web does) and gives you a REST API to send text, images, video, audio, documents, locations, polls and more, with webhooks for incoming messages and status updates.

- Perl 5.10+, core modules only (HTTP::Tiny, JSON::PP); HTTPS needs IO::Socket::SSL
- Works in Mojolicious, Dancer2, Catalyst, CGI scripts and cron jobs
- Webhook check built in

## Install

```bash
cpanm WebService::WAservix
```

## Quick start

You need a Tekservix account with WAservix and the API key of your number (Devices in the dashboard). Keep it on your server.

```perl
use WebService::WAservix;

my $wa = WebService::WAservix->new(api_key => $ENV{WASERVIX_KEY});

my $res = $wa->send_text('+15551234567', 'Hello Aline, your order is ready');
print "Queued message $res->{msgId} ($res->{status})\n";   # in_progress
```

## Sending

Messages are queued and sent one at a time per number, so each call returns right away with `status => 'in_progress'` and a `msgId`.

```perl
$wa->send_image('+15551234567', 'https://example.com/product.jpg', caption => 'Back in stock');

$wa->send_document('+15551234567', 'https://example.com/inv-1042.pdf',
    file_name => 'Invoice-1042.pdf', caption => 'Your invoice');

$wa->send_location('+15551234567', -1.9441, 30.0619, name => 'Our shop');

# Anything the API supports, including groups (JID ending in @g.us)
$wa->send_message('120363040000000000@g.us', text => 'Team meeting at 3pm');
$wa->send_message('+15551234567', poll => { name => 'Lunch?', options => ['Pizza', 'Sushi'] });
```

## Status, contacts and groups

```perl
my $info  = $wa->get_message_info(58213);      # queued, sent, delivered, read, played or failed
my $check = $wa->on_whatsapp('+15551234567');  # { exists => 1, jid => '...' }
my $conn  = $wa->get_status;                   # { status => 'connected' }

$wa->edit_message(58213, 'Corrected text');    # own text messages, about 15 minutes
my $groups = $wa->list_groups;

$wa->request(POST => '/messages/read', { msgId => '3EB0X123456789' });   # any other endpoint
```

## Webhooks

Set a webhook URL and events for the number in the dashboard. Each request carries `X-Webhook-Signature`, which equals the number's webhook secret. Mojolicious example:

```perl
post '/wa-webhook' => sub {
    my $c = shift;
    return $c->render(text => 'bad signature', status => 401)
        unless WebService::WAservix::verify_webhook($c->req->headers->header('X-Webhook-Signature'), $ENV{WASERVIX_WEBHOOK_SECRET});

    my $payload = $c->req->json;
    if ($payload->{event} eq 'messages.received') {
        my $m = $payload->{data}{messages};
        # $m->{key}{cleanedSenderPn}, $m->{messageBody}
    }
    $c->render(text => 'ok');
};
```

## Errors

Failed calls die with a `WebService::WAservix::Error` that has `status`, `message`, `errors` and `retry_after`. A 503 means the number is reconnecting: retry shortly.

## Use it responsibly

WAservix is not Meta's official WhatsApp Business Platform. There's no business verification and no per-conversation fee, but WhatsApp's spam rules apply to your number directly. Message people who expect to hear from you, warm up new numbers slowly and keep the built-in account protection on.

## More from Tekservix

- [SMS Gora SMS Gateway](https://tekservix.com/smsgora/): SMS through your own Android phones (`cpanm WebService::SmsGora`)
- [AI Sales Agent](https://tekservix.com/ai-sales-agent): answers customers on WhatsApp and SMS using your website's content
- [Website to App](https://tekservix.com/mobile-apps): turn your website into Android and iOS apps
- WAservix is also available for Node.js, Python, PHP, Go, Java/Kotlin, .NET, Ruby, Swift, Rust, Dart, Deno, Elixir, n8n and Node-RED: [github.com/TekservixHQ](https://github.com/TekservixHQ)

## License

MIT
