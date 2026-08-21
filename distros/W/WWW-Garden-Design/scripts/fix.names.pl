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

		if (exists($$item{aliases}) && exists($$item{common_name}) && ($$item{aliases} eq $$item{common_name}) )
		{
			$$item{aliases} = '';
		}

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

my(%csv_files) =
(
	attributes =>
	{
		aliases			=> false,
		column_names	=> [],
		name			=> 'attributes',
		set				=> [],
	},
	flower_locations =>
	{
		aliases			=> false,
		column_names	=> [],
		name			=> 'flower_locations',
		set				=> [],
	},
	flower_garden =>
	{
		aliases			=> true,
		column_names	=> [],
		name			=> 'flowers.garden',
		set				=> [],
	},
	flower_pipe =>
	{
		aliases			=> true,
		column_names	=> [],
		name			=> 'flowers.pipe',
		set				=> [],
	},
	flower_web =>
	{
		aliases			=> true,
		column_names	=> [],
		name			=> 'flowers.web',
		set				=> [],
	},
	flowers =>
	{
		aliases			=> true,
		column_names	=> [],
		name			=> 'flowers',
		set				=> [],
	},
	images =>
	{
		aliases			=> false,
		column_names	=> [],
		name			=> 'images',
		set				=> [],
	},
	notes =>
	{
		aliases			=> false,
		column_names	=> [],
		name			=> 'notes',
		set				=> [],
	},
	urls =>
	{
		aliases			=> false,
		column_names	=> [],
		name			=> 'urls',
		set				=> [],
	},
);
my(%fix_files) =
(
	aliases =>
	{
		name	=> 'rename.aliases',
		set		=> [],
	},
	common_name =>
	{
		name	=> 'rename.common_names',
		set		=> [],
	}
);

for my $kind (sort keys %fix_files)
{
	read_csv_file($fix_files{$kind}{name}, $fix_files{$kind}{set});

	say "$kind. fix file: $fix_files{$kind}{name}. ",
		"$kind. record count: @{[$#{$fix_files{$kind}{set} } + 1]}. ";
	#say "$$_{old_text} => $$_{new_text}" for @{$fix_files{$kind}{set} };
	say '';
}

my($count)	= 0;
my($target)	= 'common_name'; # 'common_name' or 'aliases'.

say "=> Using target: $target. Choices: 'common_name' or 'aliases' <=";

my(@fix_set);
my($item);

for my $type (sort keys %csv_files)
{
	next if ( ($target eq 'aliases') && isFalse($csv_files{$type}{aliases}) );

	$csv_files{$type}{column_names} = read_csv_file($csv_files{$type}{name}, $csv_files{$type}{set});

	say "$type. csv file: $csv_files{$type}{name}. ",
		"$type. record count: @{[$#{$csv_files{$type}{set} } + 1]}. ";
	#say "$$_{old_text} => $$_{new_text}" for @{$csv_files{$type}{set} };
	say '';

	@fix_set = @{$fix_files{$target}{set} };

	say "$type. Processing @{[$#fix_set + 1]} patches for $type";

	for my $index (0 .. $#{$csv_files{$type}{set} })
	{
		$item = $csv_files{$type}{set}[$index];

		#say "$type. Testing <$$item{$target}>";

		for my $string (@fix_set)
		{
			say "\t$type. Checking <$$string{old_text}>" if ($$string{old_text} =~ /^Flame pea/);

			if ($$string{old_text} eq $$item{$target})
			{
				$count++;

				$csv_files{$type}{set}[$index]{$target} = $$string{new_text};

				say "$type. Match $$string{old_text} => $$string{new_text}";
			}
		}
	}

	write_csv_file("data/$csv_files{$type}{name}.1.csv", $csv_files{$type}{set}, $csv_files{$type}{column_names});
}
