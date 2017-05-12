#!/usr/bin/perl

use strict;
use warnings;
use Benchmark qw(cmpthese);
use Text::TNetstrings qw(:all);

my $true = "4:true!";
my $false = "5:false!";

cmpthese(-10, {
	'true' => sub {decode_tnetstrings($true)},
	'false' => sub {decode_tnetstrings($false)},
});

