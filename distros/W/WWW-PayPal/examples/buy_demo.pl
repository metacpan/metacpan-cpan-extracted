#!/usr/bin/env perl
# Tiny end-to-end demo of the PayPal Orders v2 flow.
#
# Usage:
#   perl examples/buy_demo.pl \
#       --client-id $PAYPAL_CLIENT_ID \
#       --secret    $PAYPAL_SECRET    \
#       [--live]                      \
#       [--amount 1.00] [--currency EUR] \
#       [--listen http://*:5555]      \
#       [--return-host http://localhost:5555]
#
# Requirements:
#   cpanm Mojolicious
#
# Flow:
#   GET  /         -> landing page with "Buy" link
#   GET  /buy      -> creates order, 302 to PayPal approve_url
#   GET  /return   -> PayPal redirects buyer here, we capture and show result
#   GET  /cancel   -> buyer cancelled at PayPal
#
# Notes on OAuth / callbacks:
#   - The OAuth2 "client credentials" exchange (getting the bearer token) is
#     PURE server-to-server. There is NO inbound callback involved and
#     nothing PayPal calls on *your* host during that.
#   - `return_url` / `cancel_url` are *browser* redirects: PayPal hands the
#     URL to the buyer's browser, which then hits your server normally.
#     http://localhost is therefore fine for a local test.
#   - Webhooks (async event notifications) are a separate optional feature
#     and not needed for the buy flow.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Getopt::Long;
use Mojolicious::Lite;
use WWW::PayPal;

my %opt = (
    'client-id'   => $ENV{PAYPAL_CLIENT_ID},
    'secret'      => $ENV{PAYPAL_SECRET},
    'live'        => 0,
    'amount'      => '1.00',
    'currency'    => 'EUR',
    'listen'      => 'http://*:5555',
    'return-host' => 'http://localhost:5555',
);

GetOptions(\%opt,
    'client-id=s',
    'secret=s',
    'live!',
    'amount=s',
    'currency=s',
    'listen=s',
    'return-host=s',
) or die "bad options\n";

die "--client-id required (or set PAYPAL_CLIENT_ID)\n" unless $opt{'client-id'};
die "--secret required (or set PAYPAL_SECRET)\n"       unless $opt{'secret'};

my $pp = WWW::PayPal->new(
    client_id => $opt{'client-id'},
    secret    => $opt{'secret'},
    sandbox   => $opt{'live'} ? 0 : 1,
);

warn sprintf("[paypal] base_url=%s amount=%s %s\n",
    $pp->base_url, $opt{amount}, $opt{currency});

# ---- routes --------------------------------------------------------------

get '/' => sub {
    my $c = shift;
    my $buy = $c->url_for('/buy')->query(
        amount   => $opt{amount},
        currency => $opt{currency},
    );
    $c->render(text => <<"HTML", format => 'html');
<!doctype html>
<title>WWW::PayPal demo</title>
<h1>WWW::PayPal demo</h1>
<p>Env: @{[ $pp->sandbox ? 'SANDBOX' : 'LIVE' ]}</p>
<p>Amount: $opt{amount} $opt{currency}</p>
<p><a href="$buy">Buy now</a></p>
HTML
};

get '/buy' => sub {
    my $c = shift;
    my $amount   = $c->param('amount')   || $opt{amount};
    my $currency = $c->param('currency') || $opt{currency};

    my $order = eval {
        $pp->orders->checkout(
            amount     => $amount,
            currency   => $currency,
            return_url => $opt{'return-host'} . '/return',
            cancel_url => $opt{'return-host'} . '/cancel',
            brand_name => 'WWW::PayPal demo',
        );
    };
    if (my $err = $@) {
        $c->app->log->error("create failed: $err");
        return $c->render(status => 500, text => "create order failed: $err");
    }

    $c->app->log->info("created order " . $order->id . " -> " . $order->approve_url);
    return $c->redirect_to($order->approve_url);
};

get '/return' => sub {
    my $c = shift;
    my $token = $c->param('token');    # PayPal sends the order id as 'token'
    return $c->render(status => 400, text => 'missing token') unless $token;

    my $order = eval { $pp->orders->capture($token) };
    if (my $err = $@) {
        $c->app->log->error("capture failed: $err");
        return $c->render(status => 500, text => "capture failed: $err");
    }

    $c->render(
        format => 'html',
        text   => sprintf(<<"HTML",
<!doctype html>
<title>Paid</title>
<h1>Paid</h1>
<dl>
  <dt>Order ID</dt>    <dd>%s</dd>
  <dt>Status</dt>      <dd>%s</dd>
  <dt>Payer</dt>       <dd>%s &lt;%s&gt;</dd>
  <dt>Capture ID</dt>  <dd>%s</dd>
  <dt>Fee (cent)</dt>  <dd>%s</dd>
  <dt>Total</dt>       <dd>%s %s</dd>
</dl>
HTML
            $order->id          // '',
            $order->status      // '',
            $order->payer_name  // '',
            $order->payer_email // '',
            $order->capture_id  // '',
            $order->fee_in_cent // '',
            $order->total       // '',
            $order->currency    // '',
        ),
    );
};

get '/cancel' => sub {
    my $c = shift;
    $c->render(text => 'Cancelled by buyer.');
};

# ---- run -----------------------------------------------------------------

app->config(hypnotoad => { listen => [$opt{listen}] });
app->log->level('info');
app->start('daemon', '-l', $opt{listen});
