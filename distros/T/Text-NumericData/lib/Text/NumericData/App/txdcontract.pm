package Text::NumericData::App::txdcontract;

use Text::NumericData::App;

use strict;

# This is just a placeholder because of a past build system bug.
# The one and only version for Text::NumericData is kept in
# the Text::NumericData module itself.
our $VERSION = '1';
$VERSION = eval $VERSION;

#the infostring says it all
my $infostring = 'contract a data file by computing the mean over n input rows to produce one output row

txdcontract n < 100rows.dat > 50rows.dat

A partial bin at the end is dropped. When you choose value-based binning, there
will always be some data dropped at the end. That way, you only get mean values
that actually represent a full interval/bin. Furthermore, the input data is
assumed to be sorted according to the column chosen for value-based binning.';

our @ISA = ('Text::NumericData::App');

my $stats_stddev = 1;
my $stats_minmax = 2;

sub new
{
	my $class = shift;
	my @pars = (
		'bincol', '', 'c'
		,	'bin by values in given column instead of contracting by row count'
	,	'binsize', 1, 'b', 'size of one bin'
	,	'stats', 0, 's', 'add columns with statistic values for the bins'
		.	" ($stats_stddev: standard deviation,"
		.	" $stats_minmax: min and max values, "
		.	($stats_stddev|$stats_minmax).": stddev, min, max)"
	);

	return $class->SUPER::new
	({
		 parconf =>
		{
			info=>$infostring # default version
			# default author
			# default copyright
		}
		,pardef      => \@pars
		,pipemode    => 1
		,pipe_init   => \&preinit
		,pipe_begin  => \&init
		,pipe_data   => \&process_data
		,pipe_header => \&process_header
		,pipe_first_data => \&process_first_data
	});
}

sub preinit
{
	my $self = shift;
	my $n = shift(@{$self->{argv}});
	my $bincol = int($self->{param}{bincol});
	if($bincol > 0)
	{
		$self->{bincol} = $bincol-1;
		unless($self->{param}{binsize} > 0)
		{
			print STDERR "Need positive binsize!\n";
			return -1;
		}
		$self->{binsize} = 0+$self->{param}{binsize};
	}
	else
	{
		unless(defined $n)
		{
			print STDERR "Need n as argument!\n";
			return -1;
		}
		unless($n>0)
		{
			print STDERR "Need n>0!\n";
			return -1;
		}
		$self->{n} = int($n);
	}
	return 0;
}

sub init
{
	my $self = shift;

	$self->new_txd();
	$self->{binval} = undef;
	$self->{mean} = [];
	$self->{binbuffer} = [];
	$self->{meancount} = defined $self->{n} ? $self->{n} : 0;
	$self->{ln} = 0;
	$self->{sline} = '';
}

# Delay header printout for processing column headers.
sub process_header
{
	my $self = shift;
	my $sline = $_[0];
	$_[0] = $self->{sline};
	$self->{sline} = $sline;
}

# Append stats titles. This is rather convoluted, I need to make this nicer.
sub process_first_data
{
	my $self = shift;
	my $txd = $self->{txd};
	my $data = $txd->line_data($_[0]);
	if(@{$self->{txd}{titles}})
	{
		my $cols = @{$data};
		my $devi = $cols;
		my $mini = $self->{param}{stats} & $stats_stddev ? $devi+$cols : $cols;
		for(my $i=0; $i<$cols; ++$i)
		{
			my $tit = defined $txd->{titles}[$i] ? $txd->{titles}[$i] : ($i+1);
			$txd->{titles}[$devi+$i] = 'dev:'.$tit
				if($self->{param}{stats} & $stats_stddev);
			if($self->{param}{stats} & $stats_minmax)
			{
				$txd->{titles}[$mini+$i] = 'min:'.$tit;
				$txd->{titles}[$mini+$cols+$i] = 'max:'.$tit;
			}
		}
		return $self->{txd}->title_line();
	}
	else{  return \$self->{sline}; }
}

sub process_data
{
	my $self = shift;
	my $data = $self->{txd}->line_data($_[0]);
	my $bin_finished;
	my $binval;
	$_[0] = '';
	return
		unless defined $data;

	# Line-based binning knows already where the boundary is, can
	# compute before output.
	if(defined $self->{n})
	{
		for(my $i = 0; $i <= $#{$data}; ++$i)
		{
			$self->{mean}[$i] += $data->[$i];
		}
		push(@{$self->{binbuffer}}, [@{$data}])
			if($self->{param}{stats});
		++$self->{ln};
	}
	else # Value-based binning needs to figure out if we crossed the border.
	{
		$binval = sprintf('%.0f', $data->[$self->{bincol}]/$self->{binsize})
		*	$self->{binsize};
		$bin_finished = (@{$self->{mean}} and $binval != $self->{binval});
	}

	if($bin_finished or (defined $self->{n} and $self->{ln} == $self->{n}))
	{
		my @outdata;
		for(@{$self->{mean}})
		{
			push(@outdata, $_ /= $self->{ln});
		}
		if($self->{param}{stats} & $stats_stddev)
		{
			my @sum;
			for(my $d=0; $d<$self->{ln}; ++$d)
			{
				for(my $i=0; $i<@{$self->{mean}}; ++$i)
				{
					$sum[$i] += ($self->{binbuffer}[$d][$i] - $self->{mean}[$i])**2;
				}
			}
			for(my $i=0; $i<@{$self->{mean}}; ++$i)
			{
				push(@outdata, sqrt($sum[$i]/$self->{ln}));
			}
		}
		if($self->{param}{stats} & $stats_minmax)
		{
			my @min;
			my @max;
			for(my $d=0; $d<$self->{ln}; ++$d)
			{
				for(my $i=0; $i<@{$self->{mean}}; ++$i)
				{
					$max[$i] = $self->{binbuffer}[$d][$i]
						if( not defined $max[$i] or
						    $self->{binbuffer}[$d][$i] > $max[$i] );
					$min[$i] = $self->{binbuffer}[$d][$i]
						if( not defined $min[$i] or
						    $self->{binbuffer}[$d][$i] < $min[$i] );
				}
			}
			# Loop ensures that we really have the given amount of entries,
			# even if buffer was empty.
			for(my $i=0; $i<@{$self->{mean}}; ++$i)
			{
				push(@outdata, $min[$i]);
			}
			for(my $i=0; $i<@{$self->{mean}}; ++$i)
			{
				push(@outdata, $max[$i]);
			}
		}

		$outdata[$self->{bincol}] = $self->{binval}
			if $bin_finished;
		$_[0] = ${$self->{txd}->data_line(\@outdata)};
		@{$self->{mean}} = ();
		@{$self->{binbuffer}} = ();
		$self->{ln} = 0;
	}

	# Need to add bin values after output. Slightly twisted logic compared to
	# line-based binning.
	unless(defined $self->{n})
	{
		$self->{binval} = $binval;
		for(my $i = 0; $i <= $#{$data}; ++$i)
		{
			$self->{mean}[$i] += $data->[$i];
		}
		push(@{$self->{binbuffer}}, [@{$data}])
			if($self->{param}{stats});
		++$self->{ln};
	}
}

1;
