#!/usr/bin/env perl
use strict;
use warnings;
use feature qw(say);

use Log::Any::Adapter qw(Stdout);
use IO::Async::Loop;
use WebService::Async::UserAgent::NaHTTP;
use WebService::Bitcoin::BTCe;
use POSIX qw(strftime);

my $loop = IO::Async::Loop->new;
my $ua = WebService::Async::UserAgent::NaHTTP->new(loop => $loop);
my $btce = WebService::Bitcoin::BTCe->new(
	ua    => $ua,
	timed => sub { $loop->delay_future(@_) },
	secret => (shift(@ARGV) // die 'no secret'),
	key    => (shift(@ARGV) // die 'no key'),
);
say "Current balances:\n";
my $acc = $btce->account_balance->get;
for my $curr (sort keys %$acc) {
	printf "* %s  =>  %.3f\n", uc($curr), $acc->{$curr}
}
say "Active orders:\n";
use Data::Dumper;
my $orders = $btce->active_orders->get;
for my $id (sort keys %$orders) {
	my $order = $orders->{$id};
	my $info = $btce->order_info($id)->get;
	my $completion = 100 * (1 - ($info->{amount} / $info->{start_amount}));
	printf "* %s => %s %f (%s) at %f, %5.1f%% complete, placed %s\n",
		$id,
		$order->{type},
		$order->{amount},
		uc $order->{pair},
		$order->{rate},
		$completion,
		strftime '%Y-%m-%d %H:%M:%S', localtime $order->{timestamp_created}
	;
}
