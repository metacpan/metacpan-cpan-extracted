#!/usr/bin/env perl

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.
use open      qw(:std :utf8); # Undeclared streams in UTF-8.

use FindBin;

use MojoX::Validate::Util;

use Test::More;

use Text::CSV::Encoded;

use WWW::Garden::Design::Util::Filer;

# ------------------------------------------------

sub test_images
{
	my($filer, $checker, $test_count) = @_;

	# 1: Read flowers.csv in order to later validate the common_name column of images.csv.

	my(%flowers);

	my($path)					= "$FindBin::Bin/../data/flowers.csv";
	my($flowers)				= $filer -> read_csv_file($path);
	$flowers{$$_{common_name} }	= 1 for @$flowers;

	# 2: Read images.csv.

	my($table_name) = 'images';
	$path			=~ s/flowers/$table_name/;
	my($images)		= $filer -> read_csv_file($path);

	# 3: Validate the headings in images.csv.

	my(@expected_headings)	= sort(qw/common_name description file_name/);
	my(@got_headings)		= sort keys %{$$images[0]};

	my($result);

	for my $i (0 .. $#expected_headings)
	{
		$result = $checker -> check_equal_to
					(
						{expected => $expected_headings[$i], got => $got_headings[$i]},
						'got',
						'expected'
					);

		ok($result == 1, "Heading '$expected_headings[$i]' ok"); $test_count++;
	}

	# 4: Validate the data in images.csv.

	my($common_name, %count);
	my($file_name);

	for my $params (@$images)
	{
		# Check common names.

		$common_name = $$params{common_name};

		ok($checker -> check_key_exists(\%flowers, $common_name) == 1, "Common name '$common_name'. Name present in flowers.csv"); $test_count++;

		for my $column (@expected_headings)
		{
			ok($checker -> check_key_exists($params, $column) == 1, "Common name '$common_name', value '$$params{$column}' ok"); $test_count++;
		}

		# Check file names.

		$file_name			= $$params{file_name};
		$count{$file_name}	= 0 if (! $count{$file_name});

		$count{$file_name}++;
	}

	for $file_name (sort keys %count)
	{
		ok($checker -> check_number(\%count, $file_name, 1) == 1, "File name '$file_name' not duplicated"); $test_count++;
	}

	return $test_count;

} # End of test_images.

# ------------------------------------------------

my($checker)	= MojoX::Validate::Util -> new;
my($filer)		= WWW::Garden::Design::Util::Filer -> new;
my($test_count)	= 0;
$test_count		= test_images($filer, $checker, $test_count);

print "# Internal test count: $test_count\n";

done_testing($test_count);
