#!/usr/bin/env perl

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.
use open      qw(:std :utf8); # Undeclared streams in UTF-8.

use FindBin;

use MojoX::Validate::Util;

use Test::More;

use WWW::Garden::Design::Util::Filer;

# ------------------------------------------------

sub test_flowers
{
	my($filer, $checker, $test_count) = @_;
	my($path)		= "$FindBin::Bin/../data/flowers.csv";
	my($flowers)	= $filer -> read_csv_file($path);

	# 1: Validate the headings in properties.csv.
	# The headings must be listed here in the same order as in the file.

	my(@expected_headings)	= sort (qw/common_name scientific_name aliases height width publish/);
	my(@got_headings)		= sort keys %{$$flowers[0]};

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

	# 2: Validate the data in flowers.csv.

	my($common_name, %count);

	for my $params (@{$filer -> read_csv_file($path)})
	{
		# Test common name, and stash for duplicate testing later.

		$common_name	= $$params{common_name};
		$result			= $checker -> check_required($params, 'common_name');

		ok($result == 1, "Common name '$common_name' ok"); $test_count++;

		$count{$common_name} = 0 if (! $count{$common_name});

		$count{$common_name}++;

		# Test scientific name.

		$result = $checker -> check_required($params, 'scientific_name');

		ok($result == 1, "Common name '$common_name'. Scientific name '$$params{scientific_name} ok"); $test_count++;

		# Test aliases.

		$result = $checker -> check_optional($params, 'aliases');

		ok($result == 1, "Common name '$common_name'. Aliases '$$params{aliases} ok"); $test_count++;

		# Test publish flag.

		$result = $checker -> check_member($params, 'publish', ['Yes', 'No']);

		ok($result  == 1, "Common name '$common_name'. Publish is Yes or No"); $test_count++;

		# Test height.

		$result = $checker -> check_dimension($params, 'height', ['cm', 'm']);

		ok($result == 1, "Common name '$common_name'. Height '$$params{height}' is ok"); $test_count++;

		# Test width.

		$result = $checker -> check_dimension($params, 'width', ['cm', 'm']);

		ok($result == 1, "Common name '$common_name'. Width '$$params{width}' is ok"); $test_count++;
	}

	for $common_name (sort keys %count)
	{
		ok($checker -> check_number(\%count, $common_name, 1) == 1, "Common name '$common_name' not duplicated"); $test_count++;
	}

	return $test_count;

} # End of test_flowers.

# ------------------------------------------------

my($checker)	= MojoX::Validate::Util -> new;
my($filer)		= WWW::Garden::Design::Util::Filer -> new;
my($test_count)	= 0;
$test_count		= test_flowers($filer, $checker, $test_count);

print "# Internal test count: $test_count\n";

done_testing($test_count);
