#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Trickster;

my $app = Trickster->new;

$app->get('/', sub {
    my ($req, $res) = @_;
    return "Hello, World!";
});

$app->get('/hello/:name', sub {
    my ($req, $res) = @_;
    my $name = $req->param('name');
    return "Hello, $name!";
});

$app->to_app;
