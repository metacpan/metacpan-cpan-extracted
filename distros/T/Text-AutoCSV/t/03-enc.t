#!/usr/bin/perl

# t/03-enc.t

#
# Written by Sébastien Millet
# June 2016
#

#
# Test script for Text::AutoCSV: encoding
#

use strict;
use warnings;

use Test::More tests => 51;
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


# * *********** *
# * UTF-8 files *
# * *********** *

{
note("");
note("[UT]F-8 tests");

# R/O

my $csv = Text::AutoCSV->new(in_file => "t/${ww}e1.csv", croak_if_error => 0, sep_char => ",");
my $all = [ $csv->get_hr_all() ];
is_deeply($all,
	[{'U' => "\x{e9}"},
		{'U' => "A\x{bf}\x{ed}"}],
	"UT01 - t/e1.csv: read CSV UTF8 chars that are latin1"
);

$csv = Text::AutoCSV->new(in_file => "t/${ww}e2.csv", croak_if_error => 0, sep_char => ",");
$all = [ $csv->get_hr_all() ];
is_deeply($all,
	[{'U' => "\x{e9}"},
		{'U' => "N\x{11b}\x{10d}\x{ed}"}],
	"UT02 - t/e2.csv: read CSV UTF8 chars that are latin1+latin2"
);

$csv = Text::AutoCSV->new(in_file => "t/${ww}e3.csv", croak_if_error => 0, sep_char => ",");
$all = [ $csv->get_hr_all() ];
is_deeply($all,
	[{'U' => "\x{e9}"},
		{'U' => "N\x{11b}\x{10d}\x{ed}"}],
	"UT03 - t/e2.csv: read CSV UTF8 + BOM chars that are latin1+latin2"
);

$csv = Text::AutoCSV->new(in_file => "t/${ww}e2.csv", croak_if_error => 0, sep_char => ",",
	encoding => 'UTF-8');
$all = [ $csv->get_hr_all() ];
is_deeply($all,
	[{'U' => "\x{e9}"},
		{'U' => "N\x{11b}\x{10d}\x{ed}"}],
	"UT04 - t/e2.csv: read CSV UTF8 chars that are latin1+latin2, explicit encoding"
);

$csv = Text::AutoCSV->new(in_file => "t/${ww}e3.csv", croak_if_error => 0, sep_char => ",",
	encoding => 'UTF-8', via => '', has_headers => 0, fields_column_names => [ 'Z' ]);
$all = [ $csv->get_hr_all() ];
is_deeply($all,
		# BOM appears here as explicit via discards the use of
		#   :via(File::BOM)
	[{'Z' => "\x{feff}u"},
		{ 'Z' => "\x{e9}"},
		{ 'Z' => "N\x{11b}\x{10d}\x{ed}"}],
	"UT05 - t/e3.csv: read CSV UTF8 + BOM chars that are latin1+latin2, explicit encoding"
);

$csv = Text::AutoCSV->new(in_file => "t/${ww}e2.csv", croak_if_error => 0, sep_char => ",",
	encoding => 'UTF-8');
$all = [ $csv->get_hr_all() ];
is_deeply($all,
	[{'U' => "\x{e9}"},
		{'U' => "N\x{11b}\x{10d}\x{ed}"}],
	"UT06 - t/e2.csv: read CSV UTF8 chars that are latin1+latin2, explicit encoding option"
);

$csv = Text::AutoCSV->new(in_file => "t/${ww}e3.csv", croak_if_error => 0, sep_char => ",",
	encoding => 'UTF-8', via => ':via(File::BOM)');
$all = [ $csv->get_hr_all() ];
is_deeply($all,
		# This time BOM is specified in the encoding parameter => no mess
	[{ 'U' => "\x{e9}"},
		{ 'U' => "N\x{11b}\x{10d}\x{ed}"}],
	"UT07 - t/e3.csv: read CSV UTF8 + BOM chars that are latin1+latin2, explicit encoding with opts"
);

# R/W

my $tmpf = &get_non_existent_temp_file_name();
my $csvtmp = Text::AutoCSV->new(in_file => "t/${ww}e3.csv", croak_if_error => 0, sep_char => ",",
	out_file => $tmpf)->write();
	# We switch column name to 'Y' to 100% guarantee no confusion with previous tests
$csv = Text::AutoCSV->new(in_file => $tmpf, croak_if_error => 0, sep_char => ",",
	fields_hr => {'Y' => 'U'});
$all = [ $csv->get_hr_all() ];
is_deeply($all,
	[{'Y' => "\x{e9}"},
		{'Y' => "N\x{11b}\x{10d}\x{ed}"}],
	"UT08 - t/e3.csv: r/w: CSV UTF8 + BOM chars that are latin1+latin2"
);

$csvtmp = Text::AutoCSV->new(in_file => "t/${ww}e3.csv", croak_if_error => 0, sep_char => ",",
	out_file => $tmpf, out_encoding => 'latin2')->write();
is($csvtmp->get_in_encoding(), 'UTF-8', "UT09 - t/e3.csv: verify encoding detection");
	# We switch column name to 'Y' to 100% guarantee no confusion with previous tests
$csv = Text::AutoCSV->new(in_file => $tmpf, croak_if_error => 0, sep_char => ",",
	encoding => 'latin2', fields_hr => {'Y' => 'U'});
$all = [ $csv->get_hr_all() ];
is_deeply($all,
	[{'Y' => "\x{e9}"},
		{'Y' => "N\x{11b}\x{10d}\x{ed}"}],
	"UT10 - t/e3.csv: r/w: CSV UTF8 + BOM chars that are latin1+latin2, output latin2"
);

unlink $tmpf;
}


# * ************ *
# * latin* files *
# * ************ *

{
note("");
note("[LA]tin* tests");

# R/O

my $csv = Text::AutoCSV->new(in_file => "t/${ww}e4.csv", croak_if_error => 0, sep_char => ",",
	encoding => 'latin1');
my $all = [ $csv->get_hr_all() ];
is_deeply($all,
	[{ 'U' => "\x{e9}"},
		{ 'U' => "N\x{bf}\x{bf}\x{ed}"}],
	"LA01 - read CSV latin1, explicit encoding"
);

$csv = Text::AutoCSV->new(in_file => "t/${ww}e5.csv", croak_if_error => 0, sep_char => ",",
	encoding => 'latin2');
$all = [ $csv->get_hr_all() ];
is_deeply($all,
	[{ 'U' => "\x{e9}"},
		{ 'U' => "N\x{11b}\x{10d}\x{ed}"}],
	"LA02 - read CSV latin2, explicit encoding"
);

# R/W

my $tmpf = &get_non_existent_temp_file_name();
my $csvtmp = Text::AutoCSV->new(in_file => "t/${ww}e5.csv", croak_if_error => 0, sep_char => ",",
	encoding => 'latin2', out_file => $tmpf)->write();
$csv = Text::AutoCSV->new(in_file => $tmpf, croak_if_error => 0, sep_char => ",",
	encoding => 'latin2', fields_hr => {'Y' => 'U'});
$all = [ $csv->get_hr_all() ];
is_deeply($all,
	[{ 'Y' => "\x{e9}"},
		{ 'Y' => "N\x{11b}\x{10d}\x{ed}"}],
	"LA03 - r/w CSV latin2, explicit encoding"
);

$csvtmp = Text::AutoCSV->new(in_file => "t/${ww}e5.csv", croak_if_error => 0, sep_char => ",",
	encoding => 'latin2', out_encoding => 'UTF-8', out_file => $tmpf)->write();
$csv = Text::AutoCSV->new(in_file => $tmpf, croak_if_error => 0, sep_char => ",",
	fields_hr => {'Z' => 'U'});
$all = [ $csv->get_hr_all() ];
is_deeply($all,
	[{ 'Z' => "\x{e9}"},
		{ 'Z' => "N\x{11b}\x{10d}\x{ed}"}],
	"LA04 - r/w CSV latin2, explicit encoding, output UTF-8"
);

unlink $tmpf;
}


# * ***************** *
# * encoding failover *
# * ***************** *

{
note("");
note("[EN]coding failover");

# R/O

my $csv = Text::AutoCSV->new(in_file => "t/${ww}e5.csv", croak_if_error => 0, sep_char => ",",
	encoding => 'UTF-8,latin2');
my $all = [ $csv->get_hr_all() ];
is_deeply($all,
	[{ 'U' => "\x{e9}"},
		{ 'U' => "N\x{11b}\x{10d}\x{ed}"}],
	"EN01 - t/e5.csv: latin2 input with encoding => 'UTF-8,latin2'"
);
is($csv->get_in_encoding(), 'latin2',
	"EN02 - t/e5.csv: latin2 input with encoding => 'UTF-8,latin2' (2)");

$csv = Text::AutoCSV->new(in_file => "t/${ww}e3.csv", croak_if_error => 0, sep_char => ",",
	encoding => 'UTF-8, latin2');
$all = [ $csv->get_hr_all() ];
is_deeply($all,
	[{ 'U' => "\x{e9}"},
		{ 'U' => "N\x{11b}\x{10d}\x{ed}"}],
	"EN03 - t/e3.csv: UTF-8 input with encoding => 'UTF-8,latin2'"
);
is($csv->get_in_encoding(), 'UTF-8',
	"EN04 - t/e3.csv: UTF-8 input with encoding => 'UTF-8,latin2' (2)");

# R/W

my $tmpf = &get_non_existent_temp_file_name();
my $csvtmp = Text::AutoCSV->new(in_file => "t/${ww}e5.csv", croak_if_error => 0, sep_char => ",",
	encoding => 'UTF-8,latin2',
	out_file => $tmpf)->write();
$csv = Text::AutoCSV->new(in_file => $tmpf, croak_if_error => 0, sep_char => ",",
	encoding => 'latin2');
$all = [ $csv->get_hr_all() ];
is_deeply($all,
	[{ 'U' => "\x{e9}"},
		{ 'U' => "N\x{11b}\x{10d}\x{ed}"}],
	"EN05 - t/e5.csv: rewrite latin2 file, check encoding of target file"
);
is($csv->get_in_encoding(), 'latin2',
	"EN06 - t/e5.csv: rewrite latin2 file, check encoding of target file (2)");

$csvtmp = Text::AutoCSV->new(in_file => "t/${ww}e3.csv", croak_if_error => 0, sep_char => ",",
	encoding => 'UTF-8,latin2',
	out_file => $tmpf)->write();
$csv = Text::AutoCSV->new(in_file => $tmpf, croak_if_error => 0, sep_char => ",");
$all = [ $csv->get_hr_all() ];
is_deeply($all,
	[{ 'U' => "\x{e9}"},
		{ 'U' => "N\x{11b}\x{10d}\x{ed}"}],
	"EN07 - t/e3.csv: rewrite UTF-8 file, check encoding of target file"
);
is($csv->get_in_encoding(), 'UTF-8',
	"EN08 - t/e3.csv: rewrite UTF-8 file, check encoding of target file (2)");

my $csv1 = Text::AutoCSV->new(in_file => "t/${ww}e3.csv", croak_if_error => 0, sep_char => ",",
	out_file => $tmpf);
is($csv1->get_in_encoding(), 'UTF-8', "EN09 - t/e3.csv: detect UTF-8 by default");
$csv1->write();
my $csv2 = Text::AutoCSV->new(in_file => $tmpf, croak_if_error => 0, sep_char => ",");
is($csv2->get_in_encoding(), 'UTF-8',
	"EN10 - t/e3.csv: detect UTF-8 by default after rewrite");

$csv1 = Text::AutoCSV->new(in_file => "t/${ww}e4.csv", croak_if_error => 0, sep_char => ",",
	out_file => $tmpf);
is($csv1->get_in_encoding(), 'latin1', "EN11 - t/e4.csv: detect latin1 by default");
$csv1->write();
$csv2 = Text::AutoCSV->new(in_file => $tmpf, croak_if_error => 0, sep_char => ",");
is($csv2->get_in_encoding(), 'latin1',
	"EN12 - t/e4.csv: detect UTF-8 by default after rewrite");

my $c1 = Text::AutoCSV->new(in_file => "t/${ww}e3.csv", croak_if_error => 0, sep_char => ",",
	out_file => $tmpf, encoding => "UTF-8, latin1");
is($c1->get_in_encoding(), 'UTF-8', "EN13 - t/e3.csv: detect UTF-8 with opts");
$all = [ $c1->get_hr_all() ];
is_deeply($all,
	[{ 'U' => "\x{e9}"},
		{ 'U' => "N\x{11b}\x{10d}\x{ed}"}],
	"EN14 - t/e3.csv: detect UTF-8 with opts (2)"
);
my $c2 = Text::AutoCSV->new(in_file => "t/${ww}e4.csv", croak_if_error => 0, sep_char => ",",
	out_file => $tmpf, encoding => "UTF-8, latin1");
is($c2->get_in_encoding(), 'latin1', "EN15 - t/e4.csv: detect latin1 with opts");
$all = [ $c2->get_hr_all() ];
is_deeply($all,
	[{ 'U' => "\x{e9}"},
		{ 'U' => "N¿¿í"}],
	"EN16 - t/e4.csv: detect latin1 with opts (2)"
);
my $c3 = Text::AutoCSV->new(in_file => "t/${ww}e6.csv", croak_if_error => 0, sep_char => ",",
	out_file => $tmpf, encoding => "UTF-16LE, UTF-8, latin1");
is($c3->get_in_encoding(), 'UTF-16LE', "EN17 - t/e6.csv: detect UTF-16LE with opts");
$all = [ $c3->get_hr_all() ];
is_deeply($all,
	[{ 'U' => "\x{e9}"},
		{ 'U' => "N\x{11b}\x{10d}\x{ed}"}],
	"EN18 - t/e6.csv: detect UTF-16LE with opts (2)"
);

$c3 = Text::AutoCSV->new(in_file => "t/${ww}e7.csv", croak_if_error => 0, sep_char => ",",
	out_file => $tmpf, encoding => "UTF-16LE, UTF-8, latin1");
is($c3->get_in_encoding(), 'UTF-16LE', "EN19 - t/e7.csv: detect UTF-16LE with opts (BOM)");
$all = [ $c3->get_hr_all() ];
is_deeply($all,
	[{ 'U' => "\x{e9}"},
		{ 'U' => "N\x{11b}\x{10d}\x{ed}"}],
	"EN20 - t/e6.csv: detect UTF-16LE with opts (2) (BOM)"
);

$c1->write();
my $c1r = Text::AutoCSV->new(in_file => $tmpf, croak_if_error => 0, sep_char => ",",
	encoding => "UTF-8, latin1");
is($c1r->get_in_encoding(), 'UTF-8', "EN21 - t/e3.csv: detect UTF-8 with opts, rewritten");
$all = [ $c1r->get_hr_all() ];
is_deeply($all,
	[{ 'U' => "\x{e9}"},
		{ 'U' => "N\x{11b}\x{10d}\x{ed}"}],
	"EN22 - t/e3.csv: detect UTF-8 with opts, rewritten (2)"
);
$c2->write();
my $c2r = Text::AutoCSV->new(in_file => $tmpf, croak_if_error => 0, sep_char => ",",
	encoding => "UTF-8, latin1");
is($c2r->get_in_encoding(), 'latin1',
	"EN23 - t/e4.csv: detect latin1 with opts, rewritten");
$all = [ $c2r->get_hr_all() ];
is_deeply($all,
	[{ 'U' => "\x{e9}"},
		{ 'U' => "N¿¿í"}],
	"EN24 - t/e4.csv: detect latin1 with opts, rewritten (2)"
);
$c3->write();
my $c3r = Text::AutoCSV->new(in_file => $tmpf, croak_if_error => 0, sep_char => ",",
	encoding => "UTF-16LE, UTF-8, latin1");


#
# FIXME FIXME FIXME
#
SKIP: {

	if ($OS_IS_PLAIN_WINDOWS) {
		skip("OS is plain Windows: skipping tests EN25 and EN26", 2);
	}

	is($c3r->get_in_encoding(), 'UTF-16LE',
		"EN25 - t/e7.csv: detect UTF-16LE with opts, rewritten");
	$all = [ $c3r->get_hr_all() ];
	is_deeply($all,
		[{ 'U' => "\x{e9}"},
			{ 'U' => "N\x{11b}\x{10d}\x{ed}"}],
		"EN26 - t/e6.csv: detect UTF-16LE with opts, rewritten (2)"
	);
}


unlink $tmpf if !$DEVTIME;
}


# * ***************** *
# * encoding failover *
# * ***************** *

{
note("");
note("[OU]t encoding");


# R/W

my $tmpf = &get_non_existent_temp_file_name();
my $c1 = Text::AutoCSV->new(in_file => "t/${ww}e1.csv", croak_if_error => 0, sep_char => ",",
	out_file => $tmpf, encoding => "UTF-8, latin1", out_encoding => 'latin1');
is($c1->get_in_encoding(), 'UTF-8', "OU01 - t/e1.csv: check input file is UTF-8");

my $c2 = Text::AutoCSV->new(in_file => "t/${ww}e4.csv", croak_if_error => 0, sep_char => ",",
	out_file => $tmpf, encoding => "UTF-8, latin1", out_encoding => 'UTF-16LE');
is($c2->get_in_encoding(), 'latin1', "OU02 - t/e4.csv: check input file is latin1");

my $c3 = Text::AutoCSV->new(in_file => "t/${ww}e6.csv", croak_if_error => 0, sep_char => ",",
	out_file => $tmpf, encoding => "UTF-16LE, UTF-8, latin1", out_encoding => 'UTF-8');
is($c3->get_in_encoding(), 'UTF-16LE', "OU03 - t/e6.csv: check input file is UTF-16LE");

$c1->write();
my $c1r = Text::AutoCSV->new(in_file => $tmpf, croak_if_error => 0, sep_char => ",",
	encoding => "UTF-8, latin1");
is($c1r->get_in_encoding(), 'latin1', "OU04 - t/e1.csv: UTF-8 -> latin1, rewritten");
my $all = [ $c1r->get_hr_all() ];
is_deeply($all,
	[{ 'U' => "\x{e9}"},
		{ 'U' => "A¿í"}],
	"OU05 - t/e1.csv: UTF-8 -> latin1, rewritten (2)"
);

$c2->write();
my $c2r = Text::AutoCSV->new(in_file => $tmpf, croak_if_error => 0, sep_char => ",",
	encoding => "UTF-8, UTF-16LE, latin1");


#
# FIXME FIXME FIXME
#
SKIP: {

	if ($OS_IS_PLAIN_WINDOWS) {
		skip("OS is plain Windows: skipping tests OU06 and OU07", 2);
	}

	is($c2r->get_in_encoding(), 'UTF-16LE', "OU06 - t/e4.csv: latin1 -> UTF-16LE, rewritten");
	$all = [ $c2r->get_hr_all() ];
	is_deeply($all,
		[{ 'U' => "\x{e9}"},
			{ 'U' => "N¿¿í"}],
		"OU07 - t/e4.csv: latin1 -> UTF-16LE, rewritten (2)"
	);
}


$c3->write();
my $c3r = Text::AutoCSV->new(in_file => $tmpf, croak_if_error => 0, sep_char => ",",
	encoding => "UTF-8, latin1");
is($c3r->get_in_encoding(), 'UTF-8', "OU08 - t/e6.csv: UTF-16LE -> UTF-8, rewritten");
$all = [ $c3r->get_hr_all() ];
is_deeply($all,
	[{ 'U' => "\x{e9}"},
		{ 'U' => "N\x{11b}\x{10d}\x{ed}"}],
	"OU09 - t/e6.csv: UTF-16LE -> UTF-8, rewritten (2)"
);

unlink $tmpf if !$DEVTIME;
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

