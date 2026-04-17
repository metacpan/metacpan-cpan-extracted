#!/usr/bin/env perl
# End-to-end demo of the PayPal Subscriptions v1 flow (recurring payments).
#
# Usage:
#   perl examples/subscribe_demo.pl \
#       --client-id $PAYPAL_CLIENT_ID \
#       --secret    $PAYPAL_SECRET    \
#       [--live]                      \
#       [--price 9.99] [--currency EUR] \
#       [--plan-name 'Monthly VIP']   \
#       [--trial-days 0]              \
#       [--listen http://*:5556]      \
#       [--return-host http://localhost:5556] \
#       [--product-id PROD-...]       \
#       [--plan-id P-...]
#
# On first run WITHOUT --product-id / --plan-id, the script creates a
# product and a monthly plan in your PayPal account and prints their IDs.
# Re-run with those IDs to skip setup (PayPal products/plans are permanent
# objects — don't create them every time in production).
#
# Requirements:
#   cpanm Mojolicious
#
# Flow:
#   GET  /                -> landing page with "Subscribe" link
#   GET  /subscribe       -> creates subscription, 302 to PayPal approve_url
#   GET  /return          -> PayPal redirects buyer here; we fetch + display
#   GET  /cancel          -> buyer cancelled at PayPal (before approval)
#   GET  /status/:id      -> manual status lookup
#   POST /cancel-sub/:id  -> cancel an active subscription

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
    'price'       => '9.99',
    'currency'    => 'EUR',
    'plan-name'   => 'Monthly VIP',
    'product-name' => 'VIP membership',
    'trial-days'  => 0,
    'listen'      => 'http://*:5556',
    'return-host' => 'http://localhost:5556',
    'product-id'  => undef,
    'plan-id'     => undef,
);

GetOptions(\%opt,
    'client-id=s',
    'secret=s',
    'live!',
    'price=s',
    'currency=s',
    'plan-name=s',
    'product-name=s',
    'trial-days=i',
    'listen=s',
    'return-host=s',
    'product-id=s',
    'plan-id=s',
) or die "bad options\n";

die "--client-id required (or set PAYPAL_CLIENT_ID)\n" unless $opt{'client-id'};
die "--secret required (or set PAYPAL_SECRET)\n"       unless $opt{'secret'};

my $pp = WWW::PayPal->new(
    client_id => $opt{'client-id'},
    secret    => $opt{'secret'},
    sandbox   => $opt{'live'} ? 0 : 1,
);

warn sprintf("[paypal] base_url=%s\n", $pp->base_url);

# ---- one-time merchant setup: ensure product + plan exist ----------------

my $product_id = $opt{'product-id'};
unless ($product_id) {
    warn "[setup] creating product '$opt{'product-name'}'\n";
    my $product = $pp->products->create(
        name     => $opt{'product-name'},
        type     => 'SERVICE',
        category => 'SOFTWARE',
    );
    $product_id = $product->id;
    warn "[setup] product_id=$product_id (pass with --product-id next time)\n";
}

my $plan_id = $opt{'plan-id'};
unless ($plan_id) {
    warn sprintf("[setup] creating monthly plan '%s' at %s %s%s\n",
        $opt{'plan-name'}, $opt{price}, $opt{currency},
        $opt{'trial-days'} ? " (+ $opt{'trial-days'}d trial)" : '');
    my $plan = $pp->plans->create_monthly(
        product_id => $product_id,
        name       => $opt{'plan-name'},
        price      => $opt{price},
        currency   => $opt{currency},
        $opt{'trial-days'} ? (trial_days => $opt{'trial-days'}) : (),
    );
    # Newly created plans are 'CREATED' — activate them so subscriptions work.
    if ($plan->status ne 'ACTIVE') {
        warn "[setup] activating plan " . $plan->id . "\n";
        $plan->activate;
    }
    $plan_id = $plan->id;
    warn "[setup] plan_id=$plan_id (pass with --plan-id next time)\n";
}

warn "[ready] subscribe at $opt{'return-host'}/\n";

# ---- routes --------------------------------------------------------------

get '/' => sub {
    my $c = shift;
    my $env = $pp->sandbox ? 'SANDBOX' : 'LIVE';
    $c->render(text => <<"HTML", format => 'html');
<!doctype html>
<title>WWW::PayPal subscribe demo</title>
<h1>WWW::PayPal subscribe demo</h1>
<p>Env: $env</p>
<p>Product: $product_id</p>
<p>Plan: $plan_id ($opt{price} $opt{currency}/month)</p>
<p><a href="/subscribe">Subscribe now</a></p>
HTML
};

get '/subscribe' => sub {
    my $c = shift;
    my $sub = eval {
        $pp->subscriptions->create(
            plan_id    => $plan_id,
            return_url => $opt{'return-host'} . '/return',
            cancel_url => $opt{'return-host'} . '/cancel',
        );
    };
    if (my $err = $@) {
        $c->app->log->error("subscribe failed: $err");
        return $c->render(status => 500, text => "subscribe failed: $err");
    }
    $c->app->log->info("created subscription " . $sub->id . " -> " . ($sub->approve_url // 'no approve url'));
    return $c->redirect_to($sub->approve_url);
};

get '/return' => sub {
    my $c = shift;
    my $id = $c->param('subscription_id') || $c->param('token');
    return $c->render(status => 400, text => 'missing subscription_id') unless $id;

    my $sub = eval { $pp->subscriptions->get($id) };
    if (my $err = $@) {
        $c->app->log->error("get sub failed: $err");
        return $c->render(status => 500, text => "get sub failed: $err");
    }

    $c->render(
        format => 'html',
        text   => sprintf(<<"HTML",
<!doctype html>
<title>Subscribed</title>
<h1>Subscribed</h1>
<dl>
  <dt>Subscription ID</dt> <dd>%s</dd>
  <dt>Status</dt>          <dd>%s</dd>
  <dt>Plan</dt>            <dd>%s</dd>
  <dt>Subscriber</dt>      <dd>%s &lt;%s&gt;</dd>
  <dt>Start</dt>           <dd>%s</dd>
  <dt>Next billing</dt>    <dd>%s</dd>
</dl>
<form method="post" action="/cancel-sub/%s">
  <button type="submit">Cancel subscription</button>
</form>
HTML
            $sub->id                // '',
            $sub->status            // '',
            $sub->plan_id           // '',
            $sub->subscriber_name   // '',
            $sub->subscriber_email  // '',
            $sub->start_time        // '',
            $sub->next_billing_time // '(after approval)',
            $sub->id                // '',
        ),
    );
};

get '/cancel' => sub {
    my $c = shift;
    $c->render(text => 'Cancelled at PayPal before approval.');
};

get '/status/:id' => sub {
    my $c = shift;
    my $sub = eval { $pp->subscriptions->get($c->param('id')) };
    return $c->render(status => 500, text => "$@") if $@;
    $c->render(json => $sub->data);
};

post '/cancel-sub/:id' => sub {
    my $c = shift;
    my $id = $c->param('id');
    eval { $pp->subscriptions->cancel($id, reason => 'user cancelled via demo') };
    if (my $err = $@) {
        return $c->render(status => 500, text => "cancel failed: $err");
    }
    $c->render(text => "Cancelled subscription $id.");
};

# ---- run -----------------------------------------------------------------

app->log->level('info');
app->start('daemon', '-l', $opt{listen});
