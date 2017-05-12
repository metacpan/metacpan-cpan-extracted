#!/usr/bin/env perl
use strict;
use utf8;
use warnings qw(all);

use Test::HTTP::AnyEvent::Server;

$AnyEvent::Log::FILTER->level(q(debug));
my $server = Test::HTTP::AnyEvent::Server->new;

# Ctrl-C to kill the server
AE::cv->wait;
