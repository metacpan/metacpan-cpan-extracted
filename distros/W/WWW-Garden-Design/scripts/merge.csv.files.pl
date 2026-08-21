#!/usr/bin/env perl

use 5.30.0;
use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.
use open      qw(:std :utf8); # Undeclared streams in UTF-8.

use Data::Dumper::Concise; # For Dumper.

use File::Slurper 'read_lines';

use Encode ':fallback_all';

use Text::CSV;

# -----------------------------------------------

sub read_csv_file
{
	my($path, $set)	= @_;
	my($count)		= 0;
	my($csv)		= Text::CSV -> new;

	my($column_names);
	my($item);

	open(my $fh_in, '<', $path) || die "Can't open($path): $!\n";

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

			#$$item{aliases}			= Encode::encode('UTF-8', $$item{aliases}, DIE_ON_ERR | LEAVE_SRC);
			#$$item{common_name}		= Encode::encode('UTF-8', $$item{common_name}, DIE_ON_ERR | LEAVE_SRC);
			#$$item{scientific_name}	= Encode::encode('UTF-8', $$item{scientific_name}, DIE_ON_ERR | LEAVE_SRC);

			push @$set, {%$item};
		}
	}

	close $fh_in;

}	# End of read_csv_file.

# -----------------------------------------------

sub read_pipe_file
{
	my($path, $set)	= @_;
	my($count)		= 0;
	my($csv)		= Text::CSV -> new;
	my(@lines)		= read_lines($path);
	$path			=~ s/txt$/csv/;

	my($column_names);
	my($row);

	open(my $fh_out, ">:encoding(UTF_8)", $path);

	while (my $line = shift @lines)
	{
		$count++;

		if ($count == 1)
		{
			$column_names = [split(/\|/, $line)];

			$csv->say($fh_out, $column_names);
		}
		else
		{
			$row = [split(/\|/, $line)];

			$csv->say($fh_out, $row);

		}
	}

	close $fh_out;

}	# End of read_pipe_file.

# -----------------------------------------------

sub write_csv_file
{
	my($path, $flowers, $column_names)	= @_;
	my($count)	= 0;
	my($csv)	= Text::CSV -> new;

	say "Writing $path";

	open(my $fh_out, ">:encoding(UTF_8)", $path);

	my($status) = $csv->say($fh_out, $column_names);

	if (! $status)
	{
		say "$count: Failed to write header";
	}

	my($item);
	my($row);

	for my $key (sort keys %$flowers)
	{
		$count++;

		$item	= $$flowers{$key};
		$row	= [map{$$item{$_} } @$column_names];

		if (! defined $$row[4])
		{
			say "$count. Missing kind: ", join(', ', Dumper($item) );
		}

		# Encode aliases, common_name and scientific_name.

		#$$row[0]	= Encode::encode('UTF-8', $$row[0], DIE_ON_ERR | LEAVE_SRC);
		#$$row[1]	= Encode::encode('UTF-8', $$row[1], DIE_ON_ERR | LEAVE_SRC);
		#$$row[11]	= Encode::encode('UTF-8', $$row[11], DIE_ON_ERR | LEAVE_SRC);

		if ($$row[0] eq $$row[1])
		{
			say "$count. Aliases == Common name. $$row[1]";
		}

		$status = $csv->say($fh_out, $row);

		if (! $status)
		{
			say "$count: Failed to write $$row[1]. $$row[11]";
		}
	}

	close $fh_out;

}	# End of write_csv_file.

# -----------------------------------------------

my($garden)	= [];
my($pipe)	= [];
my($web)	= [];

read_csv_file('data/flowers.garden.csv', $garden);
read_csv_file('data/flowers.pipe.csv', $pipe);
read_csv_file('data/flowers.web.csv', $web);

say 'Record counts: ', @{[$#$garden + 1]}, '. ', @{[$#$pipe + 1]}, '. ', @{[$#$web + 1]};
#say "$_: " . Dumper($$garden[$_])	for (0 .. 1);
#say "$_: " . Dumper($$pipe[$_])	for (0 .. 1);
#say "$_: " . Dumper($$web[$_])		for (0 .. 1);

my(@garden_names) = qw/common_name scientific_name aliases height width publish/;

my($common_name);
my(%garden);
my(%record);

for (@$garden)
{
	$common_name = $$_{common_name};

	if (defined $garden{$common_name})
	{
		say "Garden. Duplicate common name: $common_name";
	}

	%record = ();

	for my $name (@garden_names)
	{
		$record{$name} = $$_{$name};
	}

	$garden{$common_name} = {%record};
}

say 'Garden key counts: ', @{[scalar keys %garden]}, '. ';

my(@pipe_names) = qw/aliases common_name height max_height max_width min_height min_width pig_latin publish scientific_name width/;

my(%pipe);

for (@$pipe)
{
	$common_name = $$_{common_name};

	if (defined $pipe{$common_name})
	{
		say "Pipe. Duplicate common name: $common_name";
	}

	%record = ();

	for my $name (@pipe_names)
	{
		$record{$name} = $$_{$name};
	}

	$pipe{$common_name} = {%record};
}

say 'Pipe key counts: ', @{[scalar keys %pipe]}, '. ';

my(@web_names) = qw/kind scientific_name common_name aliases planted thumbnail/;

my(%web);

for (@$web)
{
	$common_name = $$_{common_name};

	if (defined $web{$common_name})
	{
		say "Web. Duplicate common name: $common_name";
	}

	%record = ();

	for my $name (@web_names)
	{
		$record{$name} = $$_{$name};
	}

	$web{$common_name} = {%record};
}

say 'Web key counts: ', @{[scalar keys %web]}, '. ';

my(%flowers);
my($id);
my($scientific_name);

for my $key (keys %pipe)
{
	$common_name			= $pipe{$key}{common_name};
	$scientific_name		= $pipe{$key}{scientific_name};
	$id						= "$scientific_name$;$common_name";
	$flowers{$id}			= {};

	for my $name (@pipe_names)
	{
		$flowers{$id}{$name} = $pipe{$key}{$name};
	}

}

say 'Flowers key counts: ', @{[scalar keys %flowers]}, '. ';

for my $key (sort keys %garden)
{
	$common_name			= $garden{$key}{common_name};
	$scientific_name		= $garden{$key}{scientific_name};
	$id						= "$scientific_name$;$common_name";

	if (! defined $flowers{$id})
	{
		say "1 New common name: $common_name. $garden{$key}{scientific_name}";

		$flowers{$id} = {};
	}

	for my $name (@garden_names)
	{
		$flowers{$id}{$name} = $garden{$key}{$name} if (! $flowers{$id}{$name});
	}

}

say 'Flowers key counts: ', @{[scalar keys %flowers]}, '. ';

for my $key (sort keys %web)
{
	$common_name			= $web{$key}{common_name};
	$scientific_name		= $web{$key}{scientific_name};
	$id						= "$scientific_name$;$common_name";

	if (! defined $flowers{$id})
	{
		say "2 New common name: $common_name. $web{$key}{scientific_name}";

		$flowers{$id} = {};
	}

	for my $name (@web_names)
	{
		$flowers{$id}{$name} = $web{$key}{$name} if (! $flowers{$id}{$name});
	}

}

say 'Flowers key counts: ', @{[scalar keys %flowers]}, '. ';

my(@attr)	= qw/aliases common_name height kind max_height max_width min_height min_width pig_latin planted publish scientific_name thumbnail width/;
my($count)	= 0;

my($item);
my(%seen);

for my $key (keys %flowers)
{
	$count++;

	$item				= $flowers{$key};
	$common_name		= $$item{common_name};
	$scientific_name	= $$item{scientific_name};

	if ($common_name eq $scientific_name)
	{
		say "$count. $common_name. $$item{aliases}";
	}

	for my $attr (@attr)
	{
		$$item{$attr}	= ''	if ( (! defined $$item{$attr}) || ($$item{$attr} eq '-') );
		$seen{$attr}	= 0		if (! defined $seen{$attr});

		$seen{$attr}++;
	}

	$flowers{$key} = $item;
}

say 'Flower attributes: ';

for my $key (@attr)
{
	say "$key: $seen{$key}";
}

write_csv_file('data/flowers.csv', \%flowers, \@attr);
