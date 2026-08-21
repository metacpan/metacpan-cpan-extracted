#!/usr/bin/env perl

use strict;
use warnings;
use open qw(:std :utf8); # Undeclared streams in UTF-8.

use FindBin;

use MojoX::Validate::Util;

use Test::More;

use Text::CSV::Encoded;

use WWW::Garden::Design::Util::Filer;

# ------------------------------------------------

sub test_features
{
	my($filer, $checker, $test_count) = @_;
	my($path)		= "$FindBin::Bin/../data/flowers.csv";
	my($table_name) = 'features';
	$path			=~ s/flowers/$table_name/;
	my($features)	= $filer -> read_csv_file($path);

	# 1: Validate the headings in features.csv.

	my(@expected_headings)	= sort(qw/name hex_color publish/);
	my(@got_headings)		= sort keys %{$$features[0]};

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

	# 2: Validate the data in features.csv.

	my(%count);
	my($name);

	for my $params (@$features)
	{
		$name = $$params{name};

		ok($checker -> check_required($params, 'name') == 1, "Value '$name' ok"); $test_count++;
		ok($$params{hex_color} =~ /^#[0-9A-F]{6,6}$/i, "Value: $$params{hex_color} ok"); $test_count++;
		ok($checker -> check_member($params, 'publish', ['Yes', 'No']) == 1, "Feature name '$name', publish '$$params{publish}' ok"); $test_count++;

		$count{$name} = 0 if (! $count{$name});

		$count{$name}++;
	}

	for $name (sort keys %count)
	{
		ok($checker -> check_number(\%count, $name, 1) == 1, "Feature '$name' is unique"); $test_count++;
	}

	return $test_count;

} # End of test_features.

# ------------------------------------------------

my($checker)	= MojoX::Validate::Util -> new;
my($filer)		= WWW::Garden::Design::Util::Filer -> new;
my($test_count)	= 0;
$test_count		= test_features($filer, $checker, $test_count);

print "# Internal test count: $test_count\n";

done_testing($test_count);
