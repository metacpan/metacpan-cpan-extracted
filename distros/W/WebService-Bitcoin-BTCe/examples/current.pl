#!/usr/bin/env perl
use strict;
use warnings;
use feature qw(say);

use IO::Async::Loop;
use WebService::Async::UserAgent::NaHTTP;
use WebService::Bitcoin::BTCe;

my $loop = IO::Async::Loop->new;
my $ua = WebService::Async::UserAgent::NaHTTP->new(loop => $loop);
my $btce = WebService::Bitcoin::BTCe->new(
	ua => $ua,
	timed => sub { $loop->delay_future(@_) },
);
my $depth = $btce->depth(pair => 'btc_usd')->get;
say "Buy:  " . $depth->{highest_bid};
say "Sell: " . $depth->{lowest_ask};


