#!/usr/bin/env perl
#
# Warning: Sub crosscheck() has been cut out of Database.pm and never adapted to a non-role context.

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.
use open      qw(:std :utf8); # Undeclared streams in UTF-8.

use File::Spec;

use Getopt::Long;

use WWW::Garden::Design::Database::Pg;

use Mojo::Log;

use Pod::Usage;

# -----------------------------------------------

sub crosscheck
{
	my($self)	= @_;
	my($path)	= "$FindBin::Bin/../data/constants.csv";
	my($csv)	= Text::CSV::Encoded -> new
	({
		allow_whitespace => 1,
		encoding_in      => 'utf-8',
	});

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my(%constants);

	my($row) = 0;

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$row++;

		# Column names are in alphabetical order.

		for my $column (qw/name value/)
		{
			if (! defined $$item{$column})
			{
				print "File: $path. Row: $row. Column $column undefined. \n";
			}
		}

		$constants{$$item{name} } = $$item{value};
	}

	close $io;

	my($homepage_dir)	= $constants{homepage_dir};
	my($homepage_url)	= $constants{homepage_url};
	my($image_dir)		= $constants{image_dir};
	my($image_path)		= File::Spec -> catfile($homepage_dir, $image_dir);
	my($flowers)		= $self -> read_flowers_table;

	# Read in the actual file names.

	my(%file_list);

	my(@entries)						= read_dir $image_path;
	@entries							= sort grep{! -d File::Spec -> catfile($image_path, $_)} @entries; # Can't call sort directly on output of read_dir!
	$file_list{file_names}				= [@entries];
	@{$file_list{name_hash} }{@entries}	= (1) x @entries;

	# Check that the files which ought to be there, are.

	my($count);
	my($common_name);
	my($file_name);
	my($image);
	my($pig_latin);
	my(%real_name);
	my($scientific_name);
	my($target_dir);

	for my $flower (@$flowers)
	{
		$common_name			= $$flower{common_name};
		$scientific_name		= $$flower{scientific_name};
		$pig_latin				= $self -> scientific_name2pig_latin($flowers, $scientific_name, $common_name);
		$file_name				= "$pig_latin.0.jpg";
		$real_name{$file_name}	= 1;

		if (! $file_list{name_hash}{$file_name})
		{
			print "Missing thumbnail: $file_name\n";
		}

		for $image (@{$$flower{images} })
		{
			$target_dir				= File::Spec -> catdir($homepage_url, $image_dir);
			$file_name				= $$image{file_name} =~ s/\Q$target_dir\/\E//r;
			$real_name{$file_name}	= 1;

			if (! $file_list{name_hash}{$file_name})
			{
				print "Missing image: $file_name\n";
			}
		}
	}

	# Check for any unexpected files, .i.e present in the directory but not in images.csv.

	for my $file_name (@{$file_list{file_names} })
	{
		if (! $real_name{$file_name})
		{
				print "Unexpected image: $file_name\n";
		}
	}

	# Return 0 for OK and 1 for error.

	return 0;

} # End of crosscheck.

# -----------------------------------------------

my($log_path)		= 'log/development.log';
my($option_parser)	= Getopt::Long::Parser -> new;

my(%option);

if ($option_parser -> getoptions
(
 \%option,
	'help',
) )
{
	pod2usage(1) if ($option{'help'});

	exit WWW::Garden::Design::Database::Pg -> new(logger => Mojo::Log -> new(path => $log_path) ) -> crosscheck;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

crosscheck.pl - Check Latin names against image file names.

=head1 SYNOPSIS

crosscheck.pl [options]

	Options:
	-help

All switches can be reduced to a single letter.

Exit value: 0.

=head1 OPTIONS

=over 4

=item -help

Print help and exit.

=back

=cut
