#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

use MojoX::Validate::Util;

use Test::More;

use Text::CSV::Encoded;

use WWW::Garden::Design::Util::Filer;

# ------------------------------------------------

sub test_gardens
{
	my($filer, $checker, $test_count, $property_names) = @_;
	my($path)		= "$FindBin::Bin/../data/flowers.csv";
	my($table_name)	= 'gardens';
	$path			=~ s/flowers/$table_name/;
	my($gardens)	= $filer -> read_csv_file($path);

	# 1: Validate the headings in gardens.csv.
	# The headings must be listed here in the same order as in the file.

	my(@expected_headings)	= sort(qw/property_name garden_name description publish/);
	my(@got_headings)		= sort keys %{$$gardens[0]};

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

	# 2: Validate the data in gardens.csv.

	my($garden_name, %garden_names);
	my($property_name);

	for my $params (@$gardens)
	{
		for my $column (@expected_headings)
		{
			ok($checker -> check_required($params, $column) == 1, "Properties column '$column', value '$$params{$column}' ok"); $test_count++;

			if ($column eq 'property_name')
			{
				$garden_name	= $$params{garden_name};
				$property_name	= $$params{property_name};

				ok($checker -> check_key_exists($property_names, $property_name) == 1, "Property name '$property_name' present in properties.csv ok"); $test_count++;

				$garden_names{$property_name}				= {} if (! $garden_names{$property_name});
				$garden_names{$property_name}{$garden_name}	= 0 if (! $garden_names{$property_name}{$garden_name});

				$garden_names{$property_name}{$garden_name}++;
			}
			elsif ($column eq 'publish')
			{
				ok($checker -> check_member($params, 'publish', ['Yes', 'No']), "Garden name '$$params{garden_name}'. Publish is Yes or No"); $test_count++;
			}
		}
	}

	for $property_name (sort keys %garden_names)
	{
		for $garden_name (sort keys %{$garden_names{$property_name} })
		{
			ok($checker -> check_number($garden_names{$property_name}, $garden_name, 1) == 1, "Garden name '$garden_name' is unique within property '$property_name'"); $test_count++;
		}
	}

	return $test_count;

} # End of test_gardens.

# ------------------------------------------------

sub test_properties
{
	my($filer, $checker, $test_count, $property_names) = @_;
	my($path)		= "$FindBin::Bin/../data/flowers.csv";
	my($table_name) = 'properties';
	$path			=~ s/flowers/$table_name/;
	my($properties)	= $filer -> read_csv_file($path);

	# 1: Validate the headings in properties.csv.
	# The headings must be listed here in the same order as in the file.

	my(@expected_headings)	= sort('name','description','publish');
	my(@got_headings)		= sort keys %{$$properties[0]};

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

	# 2: Validate the data in properties.csv.

	my($property_name);

	for my $params (@$properties)
	{
		for my $column (@expected_headings)
		{
			ok($checker -> check_required($params, $column) == 1, "Properties column '$column', value '$$params{$column}' ok"); $test_count++;

			if ($column eq 'publish')
			{
				ok($checker -> check_member($params, 'publish', ['Yes', 'No']), "Property column '$column', value '$$params{publish}' ok"); $test_count++;
			}
		}

		$property_name						= $$params{name};
		$$property_names{$property_name}	= 0 if (! $$property_names{$property_name});

		$$property_names{$property_name}++;
	}

	for $property_name (sort keys %$property_names)
	{
		ok($checker -> check_number($property_names, $property_name, 1) == 1, "Property name '$property_name' not duplicated"); $test_count++;
	}

	return $test_count;

} # End of test_properties.

# ------------------------------------------------

my($checker)	= MojoX::Validate::Util -> new;
my($filer)		= WWW::Garden::Design::Util::Filer -> new;
my($test_count)	= 0;

my(%property_names);

$test_count	= test_properties($filer, $checker, $test_count, \%property_names);
$test_count	= test_gardens($filer, $checker, $test_count, \%property_names);

print "# Internal test count: $test_count\n";

done_testing($test_count);
