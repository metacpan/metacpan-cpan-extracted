#!/usr/bin/env perl

use 5.30.0;
use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.
use open      qw(:std :utf8); # Undeclared streams in UTF-8.

use boolean ':all';

use Data::Dumper::Concise; # For Dumper.

use File::Slurper 'read_lines';

use Text::CSV;

# -----------------------------------------------

sub read_csv_file
{
	my($path, $set)	= @_;
	my($count)		= 0;
	my($csv)		= Text::CSV -> new;

	my($column_names);
	my($item);

	open(my $fh_in, '<', "data/$path.csv") || die "Can't open($path): $!\n";

	while (my $line = $csv -> getline($fh_in) )
	{
		$count++;

		if ($count == 1)
		{
			$column_names = [@$line]; # Not $column_names = $line!!!
		}
		else
		{
			for my $i (0 .. $#$column_names)
			{
				$$item{$$column_names[$i]} = $$line[$i];
			}

			push @$set, {%$item};
		}
	}

	close $fh_in;

	return $column_names;

}	# End of read_csv_file.

# -----------------------------------------------

sub write_csv_file
{
	my($path, $set, $column_names)	= @_;
	my($count)	= 0;
	my($csv)	= Text::CSV -> new;

	say "Writing $path";

	open(my $fh_out, ">:encoding(UTF_8)", $path);

	my($status) = $csv->say($fh_out, $column_names);

	if (! $status)
	{
		say "$count: Failed to write header";
	}

	my($row);

	for my $item (@$set)
	{
		$count++;

		$row	= [map{$$item{$_} } @$column_names];
		$status = $csv->say($fh_out, $row);

		if (! $status)
		{
			say "$count: Failed to write $$item{common_name}";
		}
	}

	close $fh_out;

}	# End of write_csv_file.

# -----------------------------------------------

my(%files) =
(
	flowers =>
	{
		column_names	=> [],
		file_name		=> 'flowers',
		set				=> [],
	},
	web =>
	{
		column_names	=> [],
		file_name		=> 'flowers.web',
		set				=> [],
	}
);

for my $type (sort keys %files)
{
	$files{$type}{column_names} = read_csv_file($files{$type}{file_name}, $files{$type}{set});

	say "file: $files{$type}{file_name}. ",
		"record count: @{[$#{$files{$type}{set} } + 1]}. ";
	say '';
}

unshift @{$files{flowers}{column_names} }, 'kind';

my($count) = 0;

my($found, $flower_item, $flower_key);
my($kind);
my($web_item, $web_key);

for my $flower_index (0 .. $#{$files{flowers}{set} })
{
	$flower_item	= $files{flowers}{set}[$flower_index];
	$flower_key		= "$$flower_item{common_name}$;$$flower_item{scientific_name}";
	$found			= false;

	for my $web_index (0 .. $#{$files{web}{set} })
	{
		$web_item	= $files{web}{set}[$web_index];
		$web_key	= "$$web_item{common_name}$;$$web_item{scientific_name}";
		$kind		= $$web_item{kind};

		if ($web_key eq $flower_key)
		{
			$count++;

			$found = true;

			last;
		}
	}

	if (isFalse($found) )
	{
		$kind = 'Plant';
	}

	$files{flowers}{set}[$flower_index]{kind} = $kind;
}

say "$count matches";

write_csv_file("data/$files{flowers}{file_name}.1.csv", $files{flowers}{set}, $files{flowers}{column_names});
