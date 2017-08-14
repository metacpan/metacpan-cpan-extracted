#!/usr/bin/perl

# t/05-croak.t

#
# Written by Sébastien Millet
# June 2016
#

#
# Test script for Text::AutoCSV: check croak occurs as expected
#

use strict;
use warnings;

use Test::More tests => 58;
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

use File::Temp qw(tmpnam);

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


# * ************************************* *
# * Try a few things that trigger a croak *
# * ************************************* *

{
note("");
note("[CR]oak tests");

my $e = 0;
eval { Text::AutoCSV->new(in_file => "t/${ww}esc02.csv")->read(); } or $e = 1;
is($e, 0, "CR01 - t/esc02.csv: check file read works fine");

$e = 0;
eval {
	Text::AutoCSV->new(in_file => "t/${ww}nonexistentfile.csv", croak_if_error => 0, quiet => 1);
	$e = 1;
};
is($e, 1, "CR02 - t/esc02.csv: check non-existent file read produces an error (no croak)");

$e = 0;
eval { Text::AutoCSV->new(in_file => "t/${ww}nonexistentfile.csv", infoh => 0); $e = 1; };
is($e, 0, "CR03 - t/esc02.csv: check non-existent file read produces a croak (1)");

$e = 0;
eval { Text::AutoCSV->new(in_file => "t/${ww}nonexistentfile.csv", infoh => 0); } or $e = 2;
is($e, 2, "CR04 - t/esc02.csv: check non-existent file read produces a croak (2)");

$e = 0;
eval { Text::AutoCSV->new(in_file => "t/${ww}esc02.csv", one_pass => 1, infoh => 0)->read(); $e = 1};
is($e, 0, "CR05 - t/esc02.csv: check file read croaks with one_pass => 1");

$e = 0;
eval { local $SIG{__WARN__} = sub { die @_ }; Text::AutoCSV->new(in_file => "t/${ww}e4.csv",
	sep_char => ',') ->read(); $e = 1};
is($e, 1, "CR06 - t/e4.csv: check file read works fine");

$e = 0;
eval { local $SIG{__WARN__} = sub { die @_ }; Text::AutoCSV->new(in_file => "t/${ww}e4.csv",
	one_pass => 1, sep_char => ',')->read(); $e = 1};
is($e, 0, "CR07 - t/e4.csv: check file read triggers warnings with one_pass => 1");

$e = 0;
eval { local $SIG{__WARN__} = sub { die @_ }; Text::AutoCSV->new(in_file => "t/${ww}e4.csv",
	encoding => 'UTF-8, latin1', sep_char => ',')->read(); $e = 1};
is($e, 1, "CR08 - t/e4.csv: check file read works fine (2)");

$e = 0;
eval { local $SIG{__WARN__} = sub { die @_ }; Text::AutoCSV->new(in_file => "t/${ww}e4.csv",
	one_pass => 1, encoding => 'UTF-8, latin1', sep_char => ',')->read(); $e = 1};
is($e, 0, "CR09 - t/e4.csv: check file read triggers warnings with one_pass => 1 (2)");

$e = 0;
eval {
	local $SIG{__WARN__} = sub { $e = 1; };
	Text::AutoCSV->new(in_file => "t/${ww}e1.csv", sep_char => ',')->read();
} or $e = 3;
is($e, 0,
	"CR10 - t/e1.csv: check file one-read does not trigger warning");
$e = 0;
eval {
	local $SIG{__WARN__} = sub { $e = 1; };
	Text::AutoCSV->new(in_file => "t/${ww}e1.csv", sep_char => ',')->read()->read();
} or $e = 3;
is($e, 0,
	"CR11 - t/e1.csv: check file double-read triggers warning");
$e = 0;
eval {
	local $SIG{__WARN__} = sub { $e = 1; };
	Text::AutoCSV->new(in_file => "t/${ww}e1.csv", sep_char => ',')->_read_all_in_mem()->read();
} or $e = 3;
is($e, 1,
	"CR12 - t/e1.csv: check file double-read triggers warning");

$e = 0;
eval {
	local $SIG{__WARN__} = sub { $e = 1; };
	Text::AutoCSV->new(in_file => "t/${ww}e1.csv", sep_char => ',', one_pass => 1)->read()->read();
} or $e = 3;
is($e, 3,
	"CR13 - t/e1.csv: check file double-read croaks if one_pass => 1");
$e = 0;
eval {
	local $SIG{__WARN__} = sub { $e = 1; };
	Text::AutoCSV->new(in_file => "t/${ww}e1.csv", sep_char => ',', one_pass => 1)
		->_read_all_in_mem()->read();
} or $e = 3;
is($e, 3,
	"CR14 - t/e1.csv: check file double-read croaks if one_pass => 1");

$e = 0;
my $flag = 0;
eval {
	local $SIG{__WARN__} = sub { $e = 1; };
	my $c = Text::AutoCSV->new(in_file => "t/${ww}e1.csv", sep_char => ',',
		one_pass => 1, croak_if_error => 0)->read();
	$c->read();
	1;
} or $e = 3;
is($e, 1, "CR15 - t/e1.csv: check file double-read triggers warning " .
          "if one_pass => 1, croak_if_error => 0");
$e = 0;
$flag = 0;
eval {
	local $SIG{__WARN__} = sub { $e = 1; };
	my $c = Text::AutoCSV->new(in_file => "t/${ww}e1.csv", sep_char => ',',
		one_pass => 1, croak_if_error => 0)->_read_all_in_mem();
	$c->read();
	1;
} or $e = 3;
is($e, 1, "CR16 - t/e1.csv: check file double-read triggers warning " .
          "if one_pass => 1, croak_if_error => 0");
}


# * **************** *
# * check pass_count *
# * **************** *

{
note("");
note("[PA]ass count");

my $warning_count = 0;
local $SIG{__WARN__} = sub { $warning_count++; };

my $csv = Text::AutoCSV->new(in_file => "t/${ww}e1.csv", sep_char => ',');
my $pc = $csv->get_pass_count();
is($pc, 3, "PA01 - t/e1.csv: check pass_count before reading");
is($warning_count, 0, "PA02             check warning count");
$pc = $csv->read()->get_pass_count();
is($pc, 4, "PA03 - t/e1.csv: check pass_count after one complete reading");
is($warning_count, 0, "PA04             check warning count");
$pc = $csv->read()->get_pass_count();
is($pc, 5, "PA05 - t/e1.csv: check pass_count after one more complete reading");
is($warning_count, 0, "PA06             check warning count");
$pc = $csv->_read_all_in_mem()->read()->get_pass_count();
is($pc, 7, "PA07 - t/e1.csv: check pass_count after one more (again) complete reading");
is($warning_count, 1, "PA08             check warning count");

delete $SIG{__WARN__};

my $tmpf = &get_non_existent_temp_file_name();

$csv = Text::AutoCSV->new(in_file => "t/${ww}e1.csv", sep_char => ',', out_file => $tmpf,
	quiet => 1)->write();
$pc = $csv->get_pass_count();
is($pc, 4, "PA09 - t/e1.csv: check pass_count after write");
$pc = $csv->read()->get_pass_count();
is($pc, 5, "PA10 - t/e1.csv: check pass_count after write+read");
$pc = $csv->write()->write()->write()->get_pass_count();
is($pc, 8, "PA11 - t/e1.csv: check pass_count after write+read then 3 write");
$pc = $csv->read()->_read_all_in_mem()->read()->get_pass_count();
is($pc, 11, "PA12 - t/e1.csv: check pass_count after above + 3 more read");

$csv = Text::AutoCSV->new(in_file => "t/${ww}e1.csv", sep_char => ',', out_file => $tmpf,
	quiet => 1)->_read_all_in_mem()->write();
$pc = $csv->get_pass_count();
is($pc, 4, "PA13 - t/e1.csv: check pass_count after readall+write");
$pc = $csv->write()->get_pass_count();
is($pc, 4, "PA14 - t/e1.csv: check pass_count after readall+write+write");
$pc = $csv->write()->write()->write()->get_pass_count();
is($pc, 4, "PA15 - t/e1.csv: check pass_count after above + 3 write");
$pc = $csv->read()->_read_all_in_mem()->write()->write()->write()->get_pass_count();
is($pc, 6, "PA16 - t/e1.csv: check pass_count after above + several r/w");

unlink $tmpf;

$tmpf = &get_non_existent_temp_file_name();

$csv = Text::AutoCSV->new(in_file => "t/${ww}e1.csv", sep_char => ',', out_file => $tmpf,
	one_pass => 1)->read();
$pc = $csv->get_pass_count();
is($pc, 1, "PA17 - t/e1.csv: check pass_count after read, one_pass => 1");
eval { $pc = $csv->read()->get_pass_count(); 1 } or $pc = -1;
is($pc, -1, "PA18 - t/e1.csv: check pass_count after above + read, one_pass => 1");
eval { $pc = $csv->write()->get_pass_count(); 1 } or $pc = -2;
is($pc, -2, "PA19 - t/e1.csv: check pass_count after above + write, one_pass => 1");

my $e = 0;
eval { $csv->field_add_copy('CP', 'U'); 1} or $e = 1;
is($e, 1, "PA20 - t/e1.csv: check field_add_copy triggers error after read while one_pass => 1");
$e = 0;
eval { $csv->field_add_link('', ''); 1} or $e = 1;
is($e, 1, "PA21 - t/e1.csv: check field_add_link triggers error after read while one_pass => 1");
$e = 0;
eval { $csv->field_add_computed('', undef); 1} or $e = 1;
is($e, 1, "PA22 - t/e1.csv: check field_add_computed triggers error after read with one_pass => 1");

$warning_count = 0;
local $SIG{__WARN__} = sub { $warning_count++; };

$csv = Text::AutoCSV->new(in_file => "t/${ww}e1.csv", sep_char => ',', out_file => $tmpf,
	one_pass => 1, croak_if_error => 0);
$e = 0;
eval { $csv->read(); 1} or $e = 1;
is($e, 0, "PA23 - t/e1.csv: check read does not trigger a warning when called first");
is($warning_count, 0, "PA24             check warning count");
$e = 0;
eval { $csv->read(); 1} or $e = 1;
is($e, 0, "PA25 - t/e1.csv: check read triggers a warning when called afterwards");
is($warning_count, 1, "PA26             check warning count");
$e = 0;
eval { $csv->field_add_copy('CP', 'U'); 1} or $e = 1;
is($e, 0, "PA27 - t/e1.csv: check field_add_copy triggers error after read while one_pass => 1");
is($warning_count, 2, "PA28             check warning count");
$e = 0;
eval { $csv->field_add_link('', '', ''); 1} or $e = 1;
is($e, 0, "PA29 - t/e1.csv: check field_add_link triggers error after read while one_pass => 1");
is($warning_count, 3, "PA30             check warning count");
$e = 0;
eval { $csv->field_add_computed('', sub { }); 1} or $e = 1;
is($e, 0, "PA31 - t/e1.csv: check field_add_computed triggers error after read with one_pass => 1");
is($warning_count, 4, "PA32             check warning count");

delete $SIG{__WARN__};

unlink $tmpf;
}


# * ************ *
# * croaks tests *
# * ************ *

{
	note("");
	note("[CR]oaks tests");

	my $eval_failed = 0;

	eval {
		Text::AutoCSV->new(in_file => "t/${ww}l01a.csv", wrong_attr => 'pi=3.14');
	} or $eval_failed = 1;
	is($eval_failed, 1, "CR01 - bad attribute passed to Text::AutoCSV croaks (1)");
	like($@, qr/parameter.*was not listed.*wrong_attr/i,
		"CR02 - bad attribute passed to Text::AutoCSV croaks (2)");

	my $csv = Text::AutoCSV->new(in_file => "t/${ww}l01a.csv");
	$eval_failed = 0;
	eval {
		$csv->field_add_link('bla', 'bla->bla->ola', 'youpi.csv', { wrong_attr => 'pi=3.14'});
	} or $eval_failed = 1;
	is($eval_failed, 1, "CR03 - bad option passed to field_add_link croaks (1)");
	like($@, qr/parameter.*was not listed.*wrong_attr/i,
		"CR04 - bad option passed to field_add_link croaks (2)");

	$eval_failed = 0;
	eval {
		$csv->field_add_link('', '', '', { }, '');
	} or $eval_failed = 1;
	is($eval_failed, 1, "CR05 - too many options passed to field_add_link croaks (1)");
	like($@, qr/\d+ parameters were passed.*but \d+.*were expected/i,
		"CR06 - too many options passed to field_add_link croaks (2)");

	$eval_failed = 0;
	eval {
		$csv->field_add_link('', '');
	} or $eval_failed = 1;
	is($eval_failed, 1, "CR07 - too few options passed to field_add_link croaks (1)");
	like($@, qr/\d+ parameters were passed.*but \d+.*were expected/i,
		"CR08 - too few options passed to field_add_link croaks (2)");
}


done_testing();


	#
	# Return the name of a temporary file name that is guaranteed NOT to exist.
	#
	# If ever it is not possible to return such a name (file exists and cannot be
	# deleted), then stop execution.
sub get_non_existent_temp_file_name {
	my $tmpf = tmpnam();
	$tmpf = 'tmp0.csv' if $DEVTIME;

	unlink $tmpf if -f $tmpf;
	die "File '$tmpf' already exists! Unable to delete it? Any way, tests aborted." if -f $tmpf;
	return $tmpf;
}

