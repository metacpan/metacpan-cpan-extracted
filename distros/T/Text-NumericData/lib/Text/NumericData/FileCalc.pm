package Text::NumericData::FileCalc;

use strict;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(file_calc);

# Returns list ref of deletion indices, undef on failure.
sub file_calc
{
	my $ff        = shift; # formula function
	my $config    = shift; # see defaults below
	my $data      = shift; # main data set to work on
	my $files     = shift; # list of Text::NumericData::File objects to use
	my $workarray = shift; # \@A
	my $constants = shift; # \@C
	# configuration defaults
	$config =
	{
	  bycol=>0
	, fromcol=>undef
	, byrow=>0
	, skipempty=>1 # Do nothing on empty data sets,
	, rowoffset=>0 # offset for byrow ($data starting with that row)
	} unless(defined $config);

	return undef unless defined $data;

	my @delete;
	# shortcut for context-less computations
	unless(defined $files)
	{
		for my $row (0..$#{$data})
		{
			next if(not @{$data->[$row]} and $config->{skipempty});
			my $ignore = &$ff([$data->[$row]]);
			push(@delete, $row) if $ignore;
		}
		return \@delete;
	}

	# the real deal, full computation in all complexity
	my @fromcol;
	my $bycol = 0;
	$bycol = $config->{bycol}
		if defined $config->{bycol};
	my $byrow = 0;
	$byrow = $config->{byrow}
		if defined $config->{byrow};
	for my $i (0..$#{$files})
	{
		if(defined $config->{fromcol})
		{
			$fromcol[$i] = $config->{fromcol}[$i];
		}
		$fromcol[$i] = $bycol unless defined $fromcol[$i];
	}

	for my $row (0..$#{$data})
	{
		next if(not @{$data->[$row]} and $config->{skipempty});
		# Construct array for data arrays.
		my @fd = ($data->[$row]); # main data set first
		# Add the files' sets, possibly using interpolation.
		# This uses Text::Numeric::Data::File methods.
		my $realrow = $row + $config->{rowoffset};
		for my $i (0..$#{$files})
		{
			my $d = undef;
			# Correlate via row ...
			if($byrow){ $d = $files->[$i]->{data}->[$realrow]; }
			# Interpolation is possible if configured.
			else
			{
				$d = $files->[$i]->set_of($fd[0]->[$bycol], $fromcol[$i]);
			}
			push(@fd, $d);
		}
		my $ignore = 0;
		# Ignore data sets that had no match in given files.
		for(@fd){ if(not defined $_){ $ignore = 1; last; } }
		# Finally compute!
		$ignore = &$ff(\@fd, $workarray, $constants) unless $ignore;
		if($ignore){ push(@delete, $row); }
	}
	return \@delete;
}

1;

__END__

=head1 NAME

Text::NumericData::FileCalc - calculations on data sets with optional support from auxilliary data files

=head1 SYNOPSIS

Simple:

	use Text::NumericData::Calc qw(formula_function);
	use Text::NumericData::FileCalc qw(file_calc);

	@data = ([0], [30], [90]);
	$ff = formula_function('[2]=sin([1]/180*pi)');
	# result: @data = ([0,0], [30,0.5], [90,1])

Elaborate with context:

	use Text::NumericData::Calc qw(formula_function);
	use Text::NumericData::File;
	use Text::NumericData::FileCalc qw(file_calc);

	@data = ([1, 2, 3],[4, 5, 6]);
	@aux = (Text::NumericData::File->new({}, '/some/file.txd'));
	@A = ();
	@C = (42);
	# Defaults.
	%config = (bycol=>0, interpolate=>1, byrow=>0);
	# Prepare function.
	$ff = formula_function('[2]*=[1,2] + C0; A0+=[2]');
	# Evaluate on @data.
	$deletelist = file_calc($ff, \@data, \@aux, \@A, \@C, \%config);
	# On error, deletelist is undefined.

=head1 DESCRIPTION

A possibly elaborate computation involving extra Text::NumericData file handles to use data from and optional read/write data in @A and constants in @C. The configuration hash is about choosing whether to correlate data via the row index or via values in a certain column (the first one by default); in the latter case also if to use interpolation (on by default).

The elaborate example above will add to column 2 the value of column 2 in the first extra file ($txdb) multiplied by 42. Also, A0 will contain the sum over this new column 2. The configuration hash can influence things:

	# do not use interpolation
	$config{interpolation} = 0;
	# correlate via 3rd column (beware of 0-based index here)
	$config{bycol} = 2;
	# even more elaborate:
	# Use col 2 in main file, but correlate to respective value
	# in col 6 of first extra file, col 3 of the second.
	$config{fromcol} = [6,3];
	# changed my mind, correlate simply via row index
	$config{byrow} = 1;

Data sets that can not be correlated to the extra files will be marked for deletion (the zero-based index returned in an array reference).
Also, you can return a true value from your formula to indicate that a data set should be deleted:

	# Filter stuff outside our range.
	file_calc('return 1 if ([1] < 0.3 or [1] > 0.7)');

I know, this sounds a bit backwards, but it makes sense considering the general law of lazyness causing the normal case to return nothing, meaning 'false'. Also, please stick to 1 as numerical value... I might consider adding some whistles based on exact return value in future.

For formula syntax, see L<Text::NumericData::Calc>.

=head1 AUTHOR

Thomas Orgis <thomas@orgis.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2013, Thomas Orgis.

This module is free software; you
can redistribute it and/or modify it under the same terms
as Perl 5.10.0. For more details, see the full text of the
licenses in the directory LICENSES.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.
