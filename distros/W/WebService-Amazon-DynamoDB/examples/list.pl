#!/usr/bin/env perl
use strict;
use warnings;

use feature qw(say);

# A minimal example for listing tables.
# Takes region as commandline parameter.

use Log::Any::Adapter qw(Stdout);

use curry;
use IO::Async::Loop;
use WebService::Amazon::DynamoDB;

my $loop = IO::Async::Loop->new;
my $region = shift or die "Need a region - for example, $0 us-west-1";

my $ddb = WebService::Amazon::DynamoDB->new(
	loop     => $loop,
	region   => $region,
	security => 'role',
);

say "Tables found:";
$ddb->each_table(sub {
	my $tbl = shift;
	say $tbl;
}, limit => 5)->get;

say "Run that again:";
$ddb->each_table(sub {
	my $tbl = shift;
	say $tbl;
}, limit => 5)->get;
