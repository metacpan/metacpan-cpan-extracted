#!/usr/bin/env perl
use strict;
use warnings;

use WebService::Pixela;

my $pixela = WebService::Pixela->new(token => $ENV{TOKEN}, username => $ENV{USER_NAME});

# setting graph id
$pixela->graph->id('graph_id');

$pixela->webhook->create(type => 'increment');

print $pixela->webhook->hash() ."\n"; # dump webhookHash

$pixela->webhook->invoke();

$pixela->webhook->delete();
