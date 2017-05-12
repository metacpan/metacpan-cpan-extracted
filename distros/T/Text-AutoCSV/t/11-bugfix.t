#!/usr/bin/perl

# t/11-bugfix.t

#
# Written by Sébastien Millet
# June 2016, February 2017
#

#
# Test script for Text::AutoCSV: bug fixes
#

use strict;
use warnings;

use Test::More tests => 14;
#use Test::More qw(no_plan);

my $OS_IS_PLAIN_WINDOWS = !! ($^O =~ /mswin/i);
my $ww = ($OS_IS_PLAIN_WINDOWS ? 'ww' : '');

	# FIXME
	# If the below is zero, ignore this FIX ME entry
	# If the below is non zero, it'll use some hacks to ease development
my $DEVTIME = 0;

	# FIXME
	# Comment when not in dev
#use feature qw(say);
#use Data::Dumper;
#$Data::Dumper::Sortkeys = 1;

BEGIN {
	use_ok('Text::AutoCSV');
}

if ($DEVTIME) {
	note("");
	note("***");
	note("***");
	note("***  !! WARNING !!");
	note("***");
	note("***  SET \$DEVTIME TO 0 BEFORE RELEASING THIS CODE TO PRODUCTION");
	note("***  RIGHT NOW, \$DEVTIME IS EQUAL TO $DEVTIME");
	note("***");
	note("***");
	note("");
}

can_ok('Text::AutoCSV', ('new'));


# * **** *
# * bugs *
# * **** *

note("");
note("[BU]g fixes");


#
# BUG 1
#

note("BUG 1: ensure correct error is produced if link to a non-existent field");

my $csv = Text::AutoCSV->new(in_file => "t/${ww}l01a.csv", croak_if_error => 0, infoh => undef)
	->field_add_link('WHATEVER', 'A->B->NON_EXISTENT_FIELD', "t/${ww}l01b.csv");
my $eval_failed = 0;
my $msgs = '';
eval {
	local $SIG{__WARN__} = sub {
		$msgs .= "@_";
	};
	my $all = $csv->get_hr_all();
} or $eval_failed = 1;
$msgs .= "\n" . $@ if $eval_failed;
is($eval_failed, 1, "BU01-1 - check link to a non-existent field produces a croak");
like($msgs, qr/unknown field/i, "BU01-2 - check error message");
unlike($msgs, qr/in-memory CSV content discarded/i, "BU01-3 - check there is no buggy warning");


#
# BUG 2
#

note("BUG 2: ensure correct error is produced if link from a non-existent field");

$csv = Text::AutoCSV->new(in_file => "t/${ww}l01a.csv", infoh => undef)
	->field_add_link('S', 'Z->B->SITE', "t/${ww}l01b.csv");
$eval_failed = 0;
$msgs = '';
eval {
	local $SIG{__WARN__} = sub {
		$msgs .= "@_";
	};
	$csv->read();
} or $eval_failed = 1;
is($eval_failed, 1, "BU02-1 - check link from a non-existent field produces a croak");
like($@, qr/unknown field/i, "BU02-2 - check error message");
unlike($msgs, qr/uninitialized/i, "BU02-3 - check there was no warning about uninitialized value");


#
# BUG 3
#

note("BUG 3: ensure correct escape character detection in some weird cases");

$csv = Text::AutoCSV->new(in_file => "t/${ww}bugfix01.csv");
my $echar = $csv->get_escape_char();
is($echar, '"', "BU03-1 - t/${ww}bugfix01.csv: check escape character detection");
$eval_failed = 0;
eval { $csv->read(); 1 } or $eval_failed = 1;
is($eval_failed, 0, "BU03-2 - t/${ww}bugfix01.csv: check read doesn't croak");


#
# BUG 4
#

note("BUG 4: ensure proper detection of infinite recursion condition");

my $csvx = Text::AutoCSV->new(in_file => "t/${ww}bugfixrc.csv");
$eval_failed = 0;
eval {
	$csvx->field_add_computed('C', sub { $csvx->vlookup('A', 0, 'A'); return 0; })->read();
} or $eval_failed = 1;
is($eval_failed, 1, "BU04-1 - check infinite recursion condition produces an error");
like($@, qr/illegal call while read/i, "BU04-2 - check error message");


#
# BUG 5
#

note("BUG 5: correctly process times when an extra padding space exists");
note("       * If a time format is first detected with a string 'Jan 20 2017  2:00PM',");
note("       * then the separator will be assumed to be '  ' (two spaces), thus if later");
note("       * a string like 'Jan 20 2017 12:00PM' is seen, it'll (wrongly) produce an error.");

$csv = Text::AutoCSV->new(in_file => "t/${ww}dates2-99.csv", fields_dates => ['A', 'B']);
$eval_failed = 0;
eval { $csv->read(); } or $eval_failed = 1;
is($eval_failed, 0, "BUG5-1 - t/${ww}dates2-99.csv: check complete read works fine");
my $s = $csv->_dds();
is_deeply($s,
	{'.' => 1,
		'A' => '%Y-%m-%d %T',
		'B' => '%b %d %Y %I:%M%p'},
	"BUG5-2 - t/${ww}dates2-99.csv: check correct identification of AM/PM formats with pad spaces"
);


done_testing();


