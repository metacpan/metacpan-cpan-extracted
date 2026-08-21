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
	my($filer) = @_;

	my(%data);

	for my $kind (qw/attribute_types attributes flower_locations flowers images notes urls/)
	{
		$data{$kind} = $filer -> read_csv_file("$FindBin::Bin/../data/$kind.csv");
	}

	for my $key (sort keys %data)
	{
		print "Table: $key. Row count: ", scalar(@{$data{$key} }), "\n";
	}

	my($file_name) = 'data/attributes.1.csv';

=pod

	open(my $fh, '>:encoding(utf-8)', $file_name) || die "Can't open(> $file_name): $!";

	$csv -> combine(qw/common_name attribute_name range/);

	print $fh $csv -> string, "\n";

	my($attribute_name);
	my($common_name);
	my($range);

	for my $attribute (@{$data{attributes} })
	{
		$attribute_name	= $$attribute{attribute_name};
		$common_name	= $$attribute{common_name};
		$range			= $$attribute{range};

		if ($attribute_name eq 'edible')
		{
			$range = 'No' if ($range eq '');
		}
		else
		{
			$range = 'Unknown' if ($range eq '');
		}

		$csv -> combine
		(
			$common_name,
			$attribute_name,
			$range,
		);

		print $fh $csv -> string, "\n";
	}

	close($fh);

=cut

}	# End of fix.

# ------------------------------------------------

my($filer) = WWW::Garden::Design::Util::Filer -> new;

fix($filer);
