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

txdcontract 2 < 100rows.dat > 50rows.dat

A partial bin at the end is dropped. When you choose value-based binning, there
will always be some data dropped at the end. That way, you only get mean values
that actually represent a full interval/bin. Furthermore, the input data is
assumed to be sorted according to the column chosen for value-based binning.';

our @ISA = ('Text::NumericData::App');

sub new
{
	my $class = shift;
	my @pars = (
		'bincol', '', 'c'
		,	'bin by values in given column instead of contracting by row count'
	,	'binsize', 1, 'b', 'size of one bin'
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
	$self->{meancount} = defined $self->{n} ? $self->{n} : 0;
	$self->{ln} = 0;
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
		for(my $i = 0; $i <= $#{$self->{mean}}; ++$i)
		{
			$self->{mean}[$i] /= $self->{ln};
		}
		$self->{mean}[$self->{bincol}] = $self->{binval}
			if $bin_finished;
		$_[0] = ${$self->{txd}->data_line($self->{mean})};
		@{$self->{mean}} = ();
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
		++$self->{ln};
	}
}

1;
