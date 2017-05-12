#!/usr/bin/perl

# t/09-search.t

#
# Written by Sébastien Millet
# September 2016
#

#
# Test script for Text::AutoCSV: a few search options
#

use strict;
use warnings;

use Test::More tests => 62;
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

#
# search
#

my $csv = Text::AutoCSV->new(in_file => "t/${ww}s1.csv");
my $r = $csv->search('A', 'X');
is_deeply($r, [0, 1, 2, 3], "x - defaults");
$r = $csv->search('A', 'X', { trim => 0 });
is_deeply($r, [2, 3], "x - trim => 0");
$r = $csv->search('A', 'X', { case => 1 });
is_deeply($r, [1, 3], "x - case => 1");
$r = $csv->search('A', 'X', { trim => 0, case => 1 });
is_deeply($r, [3], "x - trim => 0, case => 1");
$r = $csv->search('A', '');
is_deeply($r, [ ], "x - empty");
$r = $csv->search('A', '', { ignore_empty => 0 });
is_deeply($r, [4, 5], "x - empty, ignore_empty => 0");

$r = $csv->search('B', 'Y');
is_deeply($r, [0, 4, 5, 6], "y - defaults");
$r = $csv->search('B', 'Y', { trim => 0 });
is_deeply($r, [5, 6], "y - trim => 0");
$r = $csv->search('B', 'Y', { case => 1 });
is_deeply($r, [4, 6], "y - case => 1");
$r = $csv->search('B', 'Y', { trim => 0, case => 1 });
is_deeply($r, [6], "y - trim => 0, case => 1");
$r = $csv->search('B', '');
is_deeply($r, [ ], "y - empty");
$r = $csv->search('B', '', { ignore_empty => 0 });
is_deeply($r, [1, 2], "y - empty, ignore_empty => 0");

is($csv->_get_hash_build_count(), 10, "check _hash_build_count");
for (0..10) {
	$r = $csv->search('A', 'X');
	$r = $csv->search('A', 'X', { trim => 0 });
	$r = $csv->search('A', 'X', { case => 1 });
	$r = $csv->search('A', 'X', { trim => 0, case => 1 });
	$r = $csv->search('A', '');
	$r = $csv->search('A', '', { ignore_empty => 0 });
	$r = $csv->search('B', 'Y');
	$r = $csv->search('B', 'Y', { trim => 0 });
	$r = $csv->search('B', 'Y', { case => 1 });
	$r = $csv->search('B', 'Y', { trim => 0, case => 1 });
	$r = $csv->search('B', '');
	$r = $csv->search('B', '', { ignore_empty => 0 });
}
is($csv->_get_hash_build_count(), 10, "check _hash_build_count (2)");

$csv = Text::AutoCSV->new(in_file => "t/${ww}s1.csv",
	search_trim => 0, search_case => 1, search_ignore_empty => 0);
$r = $csv->search('A', 'X');
is_deeply($r, [3], "(2) x - defaults");
$r = $csv->search('A', 'X', { trim => 1 });
is_deeply($r, [1, 3], "(2) x - trim => 1");
$r = $csv->search('A', 'X', { case => 0 });
is_deeply($r, [2, 3], "(2) x - case => 0");
$r = $csv->search('A', 'X', { trim => 1, case => 0 });
is_deeply($r, [0, 1, 2, 3], "(2) x - trim => 0, case => 1");
$r = $csv->search('A', '');
is_deeply($r, [4, 5], "(2) x - empty");
$r = $csv->search('A', '', { ignore_empty => 1 });
is_deeply($r, [ ], "(2) x - empty, ignore_empty => 1");

is($csv->_get_hash_build_count(), 5, "(2) check _hash_build_count");
for (0..10) {
	$r = $csv->search('A', 'X');
	$r = $csv->search('A', 'X', { trim => 1 });
	$r = $csv->search('A', 'X', { case => 0 });
	$r = $csv->search('A', 'X', { trim => 1, case => 0 });
	$r = $csv->search('A', '');
	$r = $csv->search('A', '', { ignore_empty => 1 });
}
is($csv->_get_hash_build_count(), 5, "(2) check _hash_build_count");

#
# search_1hr
#

$csv = Text::AutoCSV->new(in_file => "t/${ww}s1.csv");
$r = $csv->search_1hr('A', 'X');
is_deeply($r, {'A' => ' x ', 'B' => ' y '}, "search_1hr");
$r = $csv->search_1hr('A', 'X', { ignore_ambiguous => 0 });
is_deeply($r, undef, "search_1hr ignore_ambiguous => 0");
$r = $csv->search_1hr('A', 'X', { trim => 0 });
is_deeply($r, {'A' => 'x', 'B' => ''}, "search_1hr trim => 0");
$r = $csv->search_1hr('A', 'X', { case => 1 });
is_deeply($r, {'A' => ' X ', 'B' => ''}, "search_1hr case => 1");
$r = $csv->search_1hr('A', 'X', { trim => 0, case => 1 });
is_deeply($r, {'A' => 'X', 'B' => '1'}, "search_1hr trim => 0, case => 1");

$r = $csv->search_1hr('A', 'X', { ignore_ambiguous => 0, trim => 0 });
is_deeply($r, undef, "search_1hr ignore_ambiguous => 0, trim => 0");
$r = $csv->search_1hr('A', 'X', { ignore_ambiguous => 0, case => 1 });
is_deeply($r, undef, "search_1hr ignore_ambiguous => 0, case => 1");
$r = $csv->search_1hr('A', 'X', { ignore_ambiguous => 0, trim => 0, case => 1 });
is_deeply($r, {'A' => 'X', 'B' => '1'}, "search_1hr ignore_ambiguous => 0, trim => 0, case => 1");

$csv = Text::AutoCSV->new(in_file => "t/${ww}s1.csv", search_ignore_ambiguous => 0,
	search_ignore_empty => 0);
$r = $csv->search_1hr('A', 'X');
is_deeply($r, undef, "(2) search_1hr");
$r = $csv->search_1hr('A', 'X', { ignore_ambiguous => 1 });
is_deeply($r, {'A' => ' x ', 'B' => ' y '}, "(2) search_1hr ignore_ambiguous => 1");
$r = $csv->search_1hr('A', '');
is_deeply($r, undef, "(2) search_1hr empty");
$r = $csv->search_1hr('A', '', { ignore_ambiguous => 1 });
is_deeply($r, {'A' => '', 'B' => ' Y '}, "(2) search_1hr empty, ignore_ambiguous => 1");

$csv = Text::AutoCSV->new(in_file => "t/${ww}s1.csv", search_ignore_ambiguous => 0, search_trim => 0,
	search_case => 1, search_ignore_empty => 0);
$r = $csv->search_1hr('A', 'X');
is_deeply($r, {'A' => 'X', 'B' => '1'}, "(3) search_1hr");
$r = $csv->search_1hr('A', '');
is_deeply($r, undef, "(3) search_1hr empty");
$r = $csv->search_1hr('A', '', { ignore_ambiguous => 1 });
is_deeply($r, {'A' => '', 'B' => ' Y '}, "(3) search_1hr empty ignore_ambiguous => 1");
$r = $csv->search_1hr('A', '', { ignore_ambiguous => 1, ignore_empty => 1 });
is_deeply($r, undef, "(3) search_1hr empty ignore_ambiguous => 1, ignore_empty => 1");
$r = $csv->search_1hr('A', 'X', { ignore_ambiguous => 1, trim => 1, case => 0, ignore_empty => 1 });
is_deeply($r, {'A' => ' x ', 'B' => ' y '},
	"(3) search_1hr ignore_ambiguous => 1, trim => 1, case => 0, ignore_empty => 1");

#
# vlookup
#

$csv = Text::AutoCSV->new(in_file => "t/${ww}s1.csv");
$r = $csv->vlookup('A', 'X', 'B');
is($r, ' y ', "vlookup");
$r = $csv->vlookup('A', 'zz', 'B');
is($r, undef, "vlookup, not found");

$r = $csv->vlookup('A', 'X', 'B', { ignore_ambiguous => 0, value_if_ambiguous => '<amb>',
	value_if_not_found => '<nf>'});
is($r, '<amb>', "vlookup with options");
$r = $csv->vlookup('A', 'zz', 'B', { ignore_ambiguous => 0, value_if_ambiguous => '<amb>',
	value_if_not_found => '<nf>'});
is($r, '<nf>', "vlookup with options, not found");

$r = $csv->vlookup('A', 'X', 'B', { trim => 0, case => 1 });
is($r, '1', "vlookup, trim => 0, case => 1");

$r = $csv->vlookup('A', 'X', 'B', { trim => 0, case => 1, ignore_ambiguous => 0,
	value_if_ambiguous => '<amb>', value_if_not_found => '<nf>' });
is($r, '1', "vlookup with options + trim => 0, case => 1");
$r = $csv->vlookup('A', 'zz', 'B', { trim => 0, case => 1, ignore_ambiguous => 0,
	value_if_ambiguous => '<amb>', value_if_not_found => '<nf>' });
is($r, '<nf>', "vlookup with options + trim => 0, case => 1, not found");

$csv = Text::AutoCSV->new(in_file => "t/${ww}s1.csv", search_value_if_not_found => '<nf>',
	search_value_if_ambiguous => '<amb>', search_ignore_ambiguous => 0, search_trim => 0,
	search_case => 1, search_ignore_empty => 0);

$r = $csv->vlookup('A', 'X', 'B');
is($r, '1', "vlookup");
$r = $csv->vlookup('A', 'zz', 'B');
is($r, '<nf>', "vlookup (2)");
$r = $csv->vlookup('A', '', 'B');
is($r, '<amb>', "vlookup (3)");
$r = $csv->vlookup('A', 'X', 'B', { trim => 1, case => 0, ignore_ambiguous => 1,
	value_if_ambiguous => undef, value_if_not_found => 'test-nf' });
is($r, ' y ', "vlookup (4)");
$r = $csv->vlookup('A', 'zz', 'B', { trim => 1, case => 0, ignore_ambiguous => 1,
	value_if_ambiguous => undef, value_if_not_found => 'test-nf' });
is($r, 'test-nf', "vlookup (5)");
$r = $csv->vlookup('A', 'zz', 'B', { trim => 1, case => 0, ignore_ambiguous => 1,
	value_if_ambiguous => undef, value_if_not_found => undef });
is($r, undef, "vlookup (6)");

$r = $csv->vlookup('A', '', 'B', { trim => 1, case => 0, ignore_ambiguous => 1,
	value_if_ambiguous => undef, value_if_not_found => 'test-nf' });
is($r, ' Y ', "vlookup (7)");
$r = $csv->vlookup('A', '', 'B', { trim => 1, case => 0, ignore_ambiguous => 1,
	value_if_ambiguous => undef, value_if_not_found => 'test-nf', ignore_empty => 1 });
is($r, 'test-nf', "vlookup (8)");

$r = $csv->vlookup('A', '', 'B', { trim => 1, case => 0, ignore_ambiguous => 1,
	value_if_ambiguous => undef, value_if_not_found => undef, ignore_empty => 1 });
is($r, undef, "vlookup (9)");

my $w = 0;
eval {
	local $SIG{__WARN__} = sub { $w++ };
	$r = $csv->vlookup('A', '', 'B', { trime => 1 });
} or $w += 100;
is($w, 100, "vlookup (10)");

#
# value_if_found
#

$csv = Text::AutoCSV->new(in_file => "t/${ww}s1.csv");

$r = $csv->vlookup('A', 'X', 'B', { ignore_ambiguous => 0, value_if_ambiguous => '<amb>',
	value_if_not_found => '<nf>', value_if_found => '<found>'} );
is($r, '<amb>', "vlookup (11)");
$r = $csv->vlookup('A', 'zz', 'B', { ignore_ambiguous => 1, value_if_ambiguous => '<amb>',
	value_if_not_found => '<nf>', value_if_found => '<found>'} );
is($r, '<nf>', "vlookup (12)");
$r = $csv->vlookup('A', 'X', 'B', { ignore_ambiguous => 1, value_if_ambiguous => '<amb>',
	value_if_not_found => '<nf>', value_if_found => '<found>'} );
is($r, '<found>', "vlookup (13)");
$r = $csv->vlookup('A', 'X', 'B', { ignore_ambiguous => 1, value_if_ambiguous => '<amb>',
	value_if_not_found => '<nf>'} );
is($r, ' y ', "vlookup (14)");


done_testing();

