#!/usr/bin/perl

# t/06-exdoc.t

#
# Written by Sébastien Millet
# June 2016
#

#
# Test script for Text::AutoCSV: examples of documentation
#

use strict;
use warnings;

use utf8;

use Test::More tests => 16;
#use Test::More qw(no_plan);

use Time::Local;

use POSIX qw(tzset);
$ENV{TZ} = 'UTC';
eval { tzset; };

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

{
note("");
note("[EX]amples of Text::AutoCSV documentation");


# ================================================================================================
my $csv = Text::AutoCSV->new(in_file => "t/${ww}addresses.csv", walker_hr => \&walk1)->read();
sub walk1 {
	my ($hr, $stats) = @_;
	$stats->{'empty city'}++ if $hr->{'CITY'} eq '';
}
# ==========

my %stats = $csv->get_stats();
is_deeply(\%stats,
	{'empty city' => 4},
	"EX01 - walker_hr example"
);


# ================================================================================================
use List::MoreUtils qw(first_index);
$csv = Text::AutoCSV->new(in_file => "t/${ww}addresses.csv", walker_ar => \&walk2);
my @cols = $csv->get_fields_names();
my $idxCITY = first_index { /^city$/i } @cols;
die "No city field!??" if $idxCITY < 0;
$csv->read();
# ==========

sub walk2 {
	my ($ar, $stats) = @_;
	$stats->{'empty city'}++ if $ar->[$idxCITY] eq '';
}

%stats = $csv->get_stats();
is_deeply(\%stats,
	{'empty city' => 4},
	"EX02 - walker_ar example"
);

my $tmpf = &get_non_existent_temp_file_name();


# ================================================================================================
Text::AutoCSV->new(in_file => "t/${ww}addresses.csv", out_file => $tmpf, out_filter => \&filt)
	->write();
sub filt {
	my $hr = shift;
	return 1 if $hr->{'CITY'} =~ /^grenoble$/i;
	return 0;
}
# ==========

$csv = Text::AutoCSV->new(in_file => $tmpf);
my $all = [ $csv->get_hr_all() ];
is_deeply($all,
	[{'CITY' => 'Grenoble', 'PERSON' => 'Machin'}],
	"EX03 - out_filter example"
);

$csv = Text::AutoCSV->new(in_file => "t/${ww}addresses.csv", read_post_update_hr => \&updt,
	out_file => $tmpf)->write();
sub updt {
	my ($hr, $stats) = @_;
	$hr->{'CITY'} =~ s/^.*$/\U$&/;
	$stats->{'empty city encountered'}++ if $hr->{'CITY'} eq '';
}
$csv = Text::AutoCSV->new(in_file => $tmpf);
$all = [ $csv->get_hr_all() ];
is_deeply($all,
	[{'CITY' => 'GRENOBLE', 'PERSON' => 'Machin'},
		{'CITY' => '', 'PERSON' => 'Machin2'},
		{'CITY' => '', 'PERSON' => 'Bidule'},
		{'CITY' => 'PARIS', 'PERSON' => 'Truc'},
		{'CITY' => '', 'PERSON' => ''},
		{'CITY' => 'NEW YORK', 'PERSON' => 'Untel'},
		{'CITY' => '', 'PERSON' => '' }],
	"EX04 - read_post_update_hr example"
);


# ================================================================================================
Text::AutoCSV->new(in_file => "t/${ww}dirpeople.csv", out_file => $tmpf)
	->field_add_computed('FULLNAME', \&calc_fn)->write();
sub calc_fn {
	my ($field, $hr, $stats) = @_;
	my $fn = $hr->{'FIRSTNAME'} . ' ' . uc($hr->{'LASTNAME'});
	$stats->{'empty full name'}++ if $fn eq ' ';
	return $fn;
}
# ==========

$csv = Text::AutoCSV->new(in_file => $tmpf);
$all = [ $csv->get_hr_all() ];
is_deeply($all,
	[{'FIRSTNAME' => 'John', 'FULLNAME' => 'John DOE', 'LASTNAME' => 'Doe'},
		{ 'FIRSTNAME' => 'Foo', 'FULLNAME' => 'Foo BAR', 'LASTNAME' => 'Bar'}],
	"EX05 - field_add_computed example"
);


# ================================================================================================
$csv = Text::AutoCSV->new(in_file => "t/${ww}dirpeople.csv", out_file => $tmpf);
$csv->field_add_copy('UCLAST', 'LASTNAME', \&myfunc);
$csv->write();
sub myfunc { s/^.*$/<<\U$&>>/; $_; }
# ==========

$csv = Text::AutoCSV->new(in_file => $tmpf);
$all = [ $csv->get_hr_all() ];
is_deeply($all,
	[{'FIRSTNAME' => 'John', 'LASTNAME' => 'Doe', 'UCLAST' => '<<DOE>>'},
		{'FIRSTNAME' => 'Foo', 'LASTNAME' => 'Bar', 'UCLAST' => '<<BAR>>'}],
	"EX06 - field_add_copy example"
);


# ================================================================================================
my $nom_compose = 0;
my $zip_not_found = 0;
Text::AutoCSV->new(in_file => "t/${ww}pers.csv", walker_hr => \&walk)
	->field_add_link('MYCITY', 'ZIP->ZIPCODE->CITY', "t/${ww}zips.csv")->read();
sub walk {
	my $hr = shift;
	$nom_compose++ if $hr->{'NAME'} =~ m/[- ]/;
	$zip_not_found++ unless defined($hr->{'MYCITY'});
}
#print("Number of persons with a multi-part name: $nom_compose\n");
#print("Number of persons with unknown zipcode: $zip_not_found\n");
# ==========

is($nom_compose, 2, "EX07 - count1");
is($zip_not_found, 1, "EX08 - count2");


# ================================================================================================
sub in_updt {
	return 0 if !defined($_) or $_ eq '';
	my $i;
	return -$i if ($i) = $_ =~ m/^\((.*)\)$/;
	$_;
}
sub out_updt {
	return '' unless defined($_);
	return '(' . (-$_) . ')' if $_ < 0;
	$_;
}
Text::AutoCSV->new(in_file => "t/${ww}trans-euros.csv", out_file => $tmpf)
	->in_map('EUROS', \&in_updt)
	->out_map('EUROS', \&out_updt)
	->out_map('DEVISE', \&out_updt)
	->field_add_copy('DEVISE', 'EUROS', sub { sprintf("%.2f", $_ * 1.141593); } )
	->write();
# ==========

$all = [ Text::AutoCSV->new(in_file => $tmpf)->get_hr_all() ];
is_deeply($all,
	[{'DEVISE' => '2.72', 'EUROS' => '2.38', 'TRANS' => '001'},
		{'DEVISE' => '1.60', 'EUROS' => '1.40', 'TRANS' => '002'},
		{'DEVISE' => '(16.15)', 'EUROS' => '(14.15)', 'TRANS' => '003'},
		{'DEVISE' => '(1712.39)', 'EUROS' => '(1500)', 'TRANS' => '004'},
		{'DEVISE' => '0.00', 'EUROS' => '0', 'TRANS' => '005'},
		{'DEVISE' => '343.05', 'EUROS' => '300.50', 'TRANS' => '006'}],
	"EX09 - trans-euroscsv example"
);


# ==============================================================================================
sub toepoch {
	return -1 unless $_;
	return timelocal($_->second(), $_->minute(), $_->hour(),
		             $_->day(), $_->month() - 1, $_->year());
}
Text::AutoCSV->new(in_file => "t/${ww}ex1.csv", out_file => $tmpf,
	fields_dates => ['ATIME', 'MTIME'])
	->in_map('ATIME', \&toepoch)
	->in_map('MTIME', \&toepoch)
	->write();
# ==========

SKIP: {

	if ($^O =~ m/mswin/i) {
		skip("OS is plain Windows: skipping test EX10 due to TZ issue", 1);
	}

	$all = [ Text::AutoCSV->new(in_file => $tmpf)->get_hr_all() ];
	is_deeply($all,
		[{'ATIME' => '1453293296', 'MTIME' => '1456764872', 'NAME' => 'File1'},
			{'ATIME' => '-1', 'MTIME' => '1435734061', 'NAME' => 'File2'},
			{'ATIME' => '1473884099', 'MTIME' => '1473884098', 'NAME' => 'File3'}],
		"EX10 - convert to epoch"
	);

}


# ==============================================================================================
my $formatter = DateTime::Format::Strptime->new(pattern => 'DATE=%F, TIME=%T');
sub fromepoch {
	return '' if $_ < 0;
	my ($sec, $min, $hour, $day, $month, $year) = (localtime($_))[0, 1, 2, 3, 4, 5];
	return $formatter->format_datetime(
	           DateTime->new(year => $year + 1900, month => $month + 1, day => $day,
	                         hour => $hour, minute => $min, second => $sec)
	);
}
$csv = Text::AutoCSV->new(in_file => $tmpf)
	->in_map('ATIME', \&fromepoch)
	->in_map('MTIME', \&fromepoch);
# ==========

$all = [ $csv->get_hr_all() ];
is_deeply($all,
	[{'ATIME' => 'DATE=2016-01-20, TIME=12:34:56',
		'MTIME' => 'DATE=2016-02-29, TIME=16:54:32',
		'NAME' => 'File1'},
	{'ATIME' => '',
		'MTIME' => 'DATE=2015-07-01, TIME=07:01:01',
		'NAME' => 'File2'},
	{'ATIME' => 'DATE=2016-09-14, TIME=20:14:59',
		'MTIME' => 'DATE=2016-09-14, TIME=20:14:58',
		'NAME' => 'File3'}],
	"EX11 - convert from epoch"
);


# ==============================================================================================
$csv = Text::AutoCSV->new(in_file => "t/${ww}in.csv", walker_hr => \&walk3);
@cols = $csv->get_fields_names();
open my $fh, '>', $tmpf;
$csv->read();
sub walk3 {
	my %rec = %{$_[0]};
	for (@cols) {
		next if $_ eq '';
		print($fh "$_ => ", $rec{$_}, "\n");
	}
	print($fh "\n");
}
close $fh;
# ==========

open my $fh2, '<', $tmpf;
my @lines = <$fh2>;
map { chomp } @lines;
is_deeply(\@lines,
	['F1 => l1f1', 'BX => l1b x', '', 'F1 => l2: v', 'BX => l2: élève', ''],
	"EX12 - \"Flatten\" a CSV file"
);


# ==============================================================================================
$csv = Text::AutoCSV->new(in_file => "t/${ww}logins.csv");
my @badlogins1 = $csv->get_values('LOGIN', sub { m/[^a-z0-9]/ });

my @badlogins2 = grep { m/[^a-z0-9]/ } (
	Text::AutoCSV->new(in_file => "t/${ww}logins.csv")->get_values('LOGIN')
);
# ==========

is_deeply(\@badlogins1, ['beta 2', 'bad 10'], "EX13 - get_values with filter sub");
is_deeply(\@badlogins2, ['beta 2', 'bad 10'], "EX14 - get_values without filter sub");


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

