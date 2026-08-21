#!/usr/bin/env perl

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.
use open      qw(:std :utf8); # Undeclared streams in UTF-8.

use File::Slurper qw/read_dir/;

use FindBin;

use WWW::Garden::Design::Util::Filer;

# -----------------------------------------------

sub fix
{
	my($filer)	= @_;
	my(%data)	=
	(
		'flowers'	=> $filer -> read_csv_file("$FindBin::Bin/../data/flowers.csv"),
		'images'	=> $filer -> read_csv_file("$FindBin::Bin/../data/images.csv"),
	);

	my($count)	= 0;
	my(%seen)	= (common_name => {}, scientific_name => {});

	my(%name);

	for my $flower (@{$data{flowers} })
	{
		$count++;

		$name{common_name}		= $$flower{common_name};
		$name{scientific_name}	= $$flower{scientific_name};

		for my $key (sort keys %seen)
		{
			if ($seen{$key}{$name{$key} })
			{
				print "Row: $count. Duplicate $key. $name{scientific_name}. $name{common_name}. \n";
			}

			$seen{$key}{$name{$key} } = 1;
		}
	}

}	# End of fix.

# ------------------------------------------------

my($filer) = WWW::Garden::Design::Util::Filer -> new;

fix($filer);
