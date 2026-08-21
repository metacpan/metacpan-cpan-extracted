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

sub test_flower_locations
{
	my($filer, $checker, $test_count) = @_;

	# 1: Read flowers.csv in order to later validate the common_name column of flower_locations.csv.

	my(%flowers);

	my($path)					= "$FindBin::Bin/../data/flowers.csv";
	my($flowers)				= $filer -> read_csv_file($path);
	$flowers{$$_{common_name} }	= 1 for @$flowers;

	# 2: Read flower_locations.csv.

	my($table_name)			= 'flower_locations';
	$path					=~ s/flowers/$table_name/;
	my($flower_locations)	= $filer -> read_csv_file($path);

	# 2: Read properties.csv.

	my(%properties);

	$table_name				= 'properties';
	$path					=~ s/flower_locations/$table_name/;
	my($properties)			= $filer -> read_csv_file($path);
	$properties{$$_{name} }	= 1 for @$properties;

	# 2: Read gardens.csv.

	my(%gardens);

	$table_name					= 'gardens';
	$path						=~ s/properties/$table_name/;
	my($gardens)				= $filer -> read_csv_file($path);
	$gardens{$$_{garden_name} }	= 1 for @$gardens;

	# 3: Validate the headings in flower_locations.csv.

	my(@expected_headings)	= sort(qw/common_name property_name garden_name xy/);
	my(@got_headings)		= sort keys %{$$flower_locations[0]};

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

	# 4: Validate the data in flower_locations.csv.

	my($common_name);
	my($garden_name);
	my($property_name);
	my($xy, @xy, %xy);

	for my $params (@$flower_locations)
	{
		# Check common names.

		$common_name	= $$params{common_name};
		$garden_name	= $$params{garden_name};
		$property_name	= $$params{property_name};

		ok($checker -> check_key_exists(\%flowers, $common_name) == 1, "Common name '$common_name'. Name present in flowers.csv"); $test_count++;

		for my $column (@expected_headings)
		{
			ok($checker -> check_key_exists($params, $column) == 1, "Common name '$common_name', value '$$params{$column}' ok"); $test_count++;
		}

		for $xy (split(/\s+/, $$params{xy}) )
		{
			@xy										= split(/,\s*/, $xy);
			$xy{$property_name}						= {}	if (! $xy{$property_name});
			$xy{$property_name}{$garden_name}		= {}	if (! $xy{$property_name}{$garden_name});
			$xy{$property_name}{$garden_name}{$xy}	= 0		if (! $xy{$property_name}{$garden_name}{$xy});

			$xy{$property_name}{$garden_name}{$xy}++;

			ok($checker -> check_ascii_digits({x => $xy[0]}, 'x') == 1, "Common name '$common_name', xy '$xy'. X ok"); $test_count++;
			ok($checker -> check_ascii_digits({y => $xy[1]}, 'y') == 1, "Common name '$common_name', xy '$xy'. Y ok"); $test_count++;
		}

		ok($checker -> check_key_exists(\%properties, $property_name) == 1, "Property name '$property_name' ok"); $test_count++;

		ok($checker -> check_key_exists(\%gardens, $garden_name) == 1, "Garden name '$garden_name' ok"); $test_count++;
	}

	for $property_name (sort keys %xy)
	{
		for $garden_name (sort keys %{$xy{$property_name} })
		{
			for $xy (sort keys %{$xy{$property_name}{$garden_name} })
			{
				ok($checker -> check_number($xy{$property_name}{$garden_name}, $xy, 1) == 1, "Property name '$property_name'. Garden name '$garden_name'. XY '$xy' duplicated"); $test_count++;
			}
		}
	}

	return $test_count;

} # End of test_flower_locations.

# ------------------------------------------------

my($checker)	= MojoX::Validate::Util -> new;
my($filer)		= WWW::Garden::Design::Util::Filer -> new;
my($test_count)	= 0;
$test_count		= test_flower_locations($filer, $checker, $test_count);

print "# Internal test count: $test_count\n";

done_testing($test_count);
