#!/usr/bin/perl

# t/15-lock.t

#
# Written by Sébastien Millet
# June 2016
#

#
# Test script for Text::AutoCSV: hash locks
#

use strict;
use warnings;

use Test::More tests => 23;
#use Test::More qw(no_plan);

my $OS_IS_PLAIN_WINDOWS = !! ($^O =~ /mswin/i);
my $ww = ($OS_IS_PLAIN_WINDOWS ? 'ww' : '');

	# FIXME
	# Comment when not in dev
#use feature qw(say);
#use Data::Dumper;
#$Data::Dumper::Sortkeys = 1;

BEGIN {
	use_ok('Text::AutoCSV');
}

can_ok('Text::AutoCSV', ('new'));

my $csv = Text::AutoCSV->new(in_file => "t/${ww}lock01.csv", infoh => undef);
my $r0 = ($csv->get_keys())[0];
my $a = $csv->get_cell($r0, 'A');
is($a, 'a1', "LO01 - check existing field read works");
my $eval_failed = 0;
eval { $a = $csv->get_cell($r0, 'D'); 1 } or $eval_failed = 1;
is($eval_failed, 1, "LO02 - non existing field croaks");
my $r3 = ($csv->get_keys())[3];
my $hr = $csv->get_row_hr($r3);
is_deeply($hr,
	{'A' => 'a4', 'B' => 'b4', 'C' => undef},
	"LO03 - get_row_hr"
);
$a = $hr->{'A'};
is($a, 'a4', "LO04 - result if reading existing fields in hash ref");
$a = $hr->{'C'};
is($a, undef, "LO05 - result if reading existing fields in hash ref");
$eval_failed = 0;
eval { $a = $hr->{'D'}; 1 } or $eval_failed = 1;
is($eval_failed, 1, "LO06 reading non existing fields of get_row_hr croaks");

$csv = Text::AutoCSV->new(in_file => "t/${ww}lock01.csv", croak_if_error => 0);
$r3 = ($csv->get_keys())[3];
$hr = $csv->get_row_hr($r3);
is_deeply($hr,
	{'A' => 'a4', 'B' => 'b4', 'C' => undef},
	"LO07 - get_row_hr, croak_if_error => 0"
);
$a = $hr->{'A'};
is($a, 'a4', "LO08 - get_row_hr, existing field, croak_if_error => 0");
$a = $hr->{'C'};
is($a, undef, "LO09 - get_row_hr, existing field (undef val), croak_if_error => 0");
$a = $hr->{'D'};
is($a, undef, "LO10 - get_row_hr, non existing field, croak_if_error => 0");

$csv = Text::AutoCSV->new(in_file => "t/${ww}lock01.csv");
$hr = $csv->search_1hr('A', 'a2');
$a = $hr->{'C'};
is($a, 'c2', "LO11 - search_1hr, existing field");
$eval_failed = 0;
eval { $a = $hr->{'D'}; 1 } or $eval_failed = 1;
is($eval_failed, 1, "LO12 - search_1hr, non existing field");
like($@, qr/key.*'D'/, "LO13 - walker_hr, non existent field, check error messasge");

$csv = Text::AutoCSV->new(in_file => "t/${ww}lock01.csv", croak_if_error => 0);
$hr = $csv->search_1hr('A', 'a2');
$a = $hr->{'C'};
is($a, 'c2', "LO14 - search_1hr, existing field, croak_if_error => 0");
$eval_failed = 0;
eval { $a = $hr->{'D'}; 1 } or $eval_failed = 1;
is($eval_failed, 0, "LO14 - search_1hr, non existing field, croak_if_error => 0");
is($a, undef, "LO15 - search_1hr, non existing field, croak_if_error => 0 (2)");

my $sa = '';
my $sd = '';
Text::AutoCSV->new(in_file => "t/${ww}lock01.csv", walker_hr => \&walka)->read();
is($sa, '::a1::a2::::a4::finA', "LO16 - walker_hr");
$eval_failed = 0;
eval { Text::AutoCSV->new(in_file => "t/${ww}lock01.csv", walker_hr => \&walkd)->read(); 1 }
	or $eval_failed = 1;
is($eval_failed, 1, "LO17 - walker_hr, non existent field");
like($@, qr/key.*'D'/, "LO18 - walker_hr, non existent field, check error messasge");

$sa = '>';
$sd = '>';
Text::AutoCSV->new(in_file => "t/${ww}lock01.csv", walker_hr => \&walka,
	croak_if_error => 0)->read();
is($sa, '>::a1::a2::::a4::finA', "LO19 - walker_hr, croak_if_error => 0");
Text::AutoCSV->new(in_file => "t/${ww}lock01.csv", walker_hr => \&walkd,
	croak_if_error => 0)->read();
is($sd, '>----------', "LO20 - walker_hr, non existent field, croak_if_error => 0");

sub walka {
	my $h = $_[0];
	$sa .= '::' . $h->{'A'};
}
sub walkd {
	my $h = $_[0];
	my $vald = $h->{'D'};
	$vald = '' unless defined($vald);
	$sd .= '--' . $vald;
}


done_testing();

