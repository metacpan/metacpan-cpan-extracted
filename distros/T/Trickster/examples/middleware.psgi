#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Trickster;
use Plack::Builder;

my $app = Trickster->new;

$app->get('/', sub {
    my ($req, $res) = @_;
    return $res->html('<h1>Middleware Example</h1><p>Check /api/status</p>');
});

$app->get('/api/status', sub {
    my ($req, $res) = @_;
    return $res->json({ status => 'ok', timestamp => time });
});

# Wrap with Plack middleware
builder {
    enable 'AccessLog', format => 'combined';
    enable 'Runtime';
    enable 'ContentLength';
    $app->to_app;
};
