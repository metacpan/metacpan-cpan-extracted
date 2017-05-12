package Text::NumericData::Stat;

# TODO: Integrate into Text::NumericData::File already.
# Also, return something for single data sets; just set non-computable measures to soemthing invalid.

use Text::NumericData::File;

use strict;

# Generate a statistics file out of given input file.
# Gives and takes Text::NumericData::File objects.
# This could be a method of Text::NumericData::File, but it doesn't have to.
sub generate
{
	my $in = shift;
	my $out = Text::NumericData::File->new($in->{config});
	my @mean;  # arithmetic mean
	my @error; # standard error, sqrt(mean sq. error / N-1)

	my $N = @{$in->{data}};
	return $out if $N < 2;
	my $S = @{$in->{data}[0]};

	for my $d (@{$in->{data}})
	{
		for my $i (0 .. $S-1)
		{
			$mean[$i] += $d->[$i];
		}
	}
	for my $i (0 .. $S-1)
	{
		$mean[$i] /= $N;
	}
	for my $d (@{$in->{data}})
	{
		for my $i (0 .. $S-1)
		{
			$error[$i] += ($d->[$i]-$mean[$i])**2;
		}
	}
	for my $i (0 .. $S-1)
	{
		$error[$i] = sqrt($error[$i]/($N-1));
	}
	$out->{title} = 'Statistics';
	$out->{title} .= ' of '.$in->{title} if defined $in->{title};
	$out->{titles} = ['column', 'name', 'mean', 'stderr'];
	for my $s (1 .. $S)
	{
		my $name = $in->{titles}[$s-1];
		if(defined $name)
		{
			$out->filter_text($name); # play safe since there is no quoting in data (yet?)
		}
		else
		{
			$name = "col$s";
		}
		$out->{data}[$s-1] = [ $s, $name, $mean[$s-1], $error[$s-1] ];
	}
	return $out;
}

1;

__END__


=head1 NAME

Text::NumericData::Stat - generate statistics for Text::NumericData::File objects

=head1 SYNOPSIS

	use Text::NumericData::Stat;

	# read some input file (all columns numeric)
	my $file = new Text::NumericData::File(\%config,$filename);

	my $statfile = Text::NumericData::Stat::generate($file);

	# use individual values
	print "mean value of first column: ",$statfile->{data}[0][0],"\n";
	print "standard error of first column: ",$statfile->{data}[0][1],"\n";	
	# or just write it down
	$statfile->Write($outfilename);

	# one can also restrict statistics to certain columns
	# indices zero-based
	$statfile = Text::NumericData::Stat::generate($file, [0, 3, 8]);

=head1 DESCRIPTION

This takes a Text::NumericData::File as input and computes statistics for each column, producing a new Text::NumericData::File with each data set representing a column of the input file, the columns of the new file containing the respective mean and standard deviation values (or more statistic measures in future).
