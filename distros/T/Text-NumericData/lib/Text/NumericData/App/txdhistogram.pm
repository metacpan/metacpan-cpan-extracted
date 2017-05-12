package Text::NumericData::App::txdhistogram;

use Text::NumericData::App;

#the infostring says it all
my $infostring = "create histogrms of textual data files

	$0 3 < data.dat
would print out a histogram of column 3 in data.dat

You can also choose to apply a weight to the data points an influence the binning. Default value for the colum is the last one present in the file.";

our @ISA = ('Text::NumericData::App');

sub new
{
	my $class = shift;

	return $class->SUPER::new
	({
		parconf=>
		{
			 info=>$infostring # default version
			# default author
			# default copyright
		}
	,	pardef=>[
			'binwidth', 0, 'w', 'width of one bin represented by one histogram point (overrides bincount)'
		,	'bincount', 10, 'n', 'specify fixed number of bins (dividing min-max range)'
		,	'discrete', 0, 'd', 'do not use binning, count on discrete points (text string comparison, no rounding!)'
		,	'weightcol', 0, 'W', 'column containing weights to add instead of simple counting'
		]
	,	filemode=>1
	,	pipemode=>1
	,	pipe_init=>\&preinit
	,	pipe_file=>\&process_file
	});
}

sub preinit
{
	my $self = shift;
	$self->{col} = shift @{$self->{argv}};
	$self->{guesscol} = not defined $self->{col};
	unless($self->{guesscol} or $self->{col} >= 1)
	{
		print STDERR "Need column >= 1!\n";
		return -1;
	}
	return 0;
}

sub process_file
{
	my $self = shift;
	my $param = $self->{param};
	my $txd = $self->{txd};

	my $col = $self->{guesscol}
	?	$txd->columns()
	:	$self->{col};	

	--$col; # Now used as index.
	my $min = $txd->{data}[0][$col];
	my $max = $min;

	# Figure out range and binning.
	for(@{$txd->{data}})
	{
		$min = $_->[$col] if $_->[$col] < $min;
		$max = $_->[$col] if $_->[$col] > $max;
	}

	my $range = $max - $min;

	# A bit messy, but let's play safe on empty range.
	unless($range > 0)
	{
		# Nothing at all?
		return unless @{$txd->{data}};
		# Everything in one place? Let's add it up.
		my $val = $txd->{data}[0][$col];
		my $mass = $txd->{records};
		if($param->{weightcol})
		{
			my $wc = $param->{weightcol}-1;
			$mass = 0;
			# more elaborate work
			for(@{$txd->{data}})
			{
				next unless (defined $_->[$col] and defined $_->[$wc]);
				$mass += $_->[$wc];
			}
		}
		print {$self->{out}} ${$txd->data_line([$val, $mass])};
		return;
	}

	# Got a real range, got to get out some bins.
	my $binwidth = $param->{binwidth};
	unless($binwidth > 0)
	{
		return unless $param->{bincount} > 0;
		$binwidth = $range / $param->{bincount};
	}
	return unless $binwidth > 0;


	my @hist; # list of bin sums, coordinates added later
	my @points;

	if($param->{discrete})
	{
		my %dhist;
		if($param->{weightcol})
		{
			my $wc = $param->{weightcol}-1;
			for(@{$txd->{data}})
			{
				# Rather paranoid, that.
				next unless (defined $_->[$col] and defined $_->[$wc]);
				$dhist{$_->[$col]} += $_->[$wc];
			}
		}
		else
		{
			# Finally, the simple "normal" case.
			for(@{$txd->{data}})
			{
				next unless defined $_->[$col];
				++$dhist{$_->[$col]};
			}
		}

		for(sort {$a <=> $b} keys %dhist)
		{
			push(@points, $_);
			push(@hist, $dhist{$_});
		}
	}
	else
	{
		# For clarity and perhaps efficiency: Duplicate this, avoiding inner branching.
		if($param->{weightcol})
		{
			my $wc = $param->{weightcol}-1;
			for(@{$txd->{data}})
			{
				# Rather paranoid, that.
				next unless (defined $_->[$col] and defined $_->[$wc]);
				# Compute zero-based bin index.
				my $bin = int(($_->[$col]-$min)/$binwidth);
				# Add weight to that bin.
				$hist[$bin] += $_->[$wc];
			}
		}
		else
		{
			# Finally, the simple "normal" case.
			for(@{$txd->{data}})
			{
				next unless defined $_->[$col];
				my $bin = int(($_->[$col]-$min)/$binwidth);
				++$hist[$bin];
			}
		}

		for(my $i=0; $i<@hist; ++$i)
		{
			$points[$i] = $min+(0.5+$i)*$binwidth;
		}
	}

	# Got the bin values, construct data lines out of them.
	for(my $i=0; $i<@hist; ++$i)
	{
		my $mass = $hist[$i];
		# Ensure that zero is zero and not just some empty string.
		$mass = 0 unless defined $mass;
		my $point = $points[$i];
		print {$self->{out}} ${$txd->data_line([$point,$mass])};
	}
}

1;
