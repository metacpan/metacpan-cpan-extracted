package Text::NumericData::App::txdrecycle;

use Text::NumericData::App;

use strict;

#the infostring says it all
my $infostring = 'Rearrange lines (records) in files in accordance to changing the viewport along a cyclic coordinate.

This is experimental work, so no usage example yet. But one hint: I designed this one with moving the viewport of gnuplot plots of cyclic data. It assumest sorted data along the coordinate (ascending or descending). To make it work with 3D plots, it processes blocks of data (separated by blank line) as independent "scans" (for gnuplot pm3d mode, for example).';

our @ISA = ('Text::NumericData::App');

sub new
{
	my $class = shift;
	my @pars =
	(
	  'column', 1, 'c',
	    'the column to use as coordiante'
	, 'shift', 0.25, 's',
	    'shift the viewport by that value (nearest existing data point), direction is subject to misunderstandings'
	);
	return $class->SUPER::new
	({
		 parconf=>
		{
			 info=>$infostring # default version,
			# default author
			# default copyright
		}
		,pardef=>\@pars
		,filemode=>0
		,pipemode=>1
		,pipe_init=>\&preinit
		,pipe_begin=>\&begin
		,pipe_line=>\&line
		,pipe_end=>\&end
	});
}

sub preinit
{
	my $self = shift;
	my $param = $self->{param};

	$self->{col} = $param->{column}-1;
	if($self->{col} < 0)
	{
		print STDERR "txdrecycle: Non-positive column does not work!\n";
		return -1;
	}

	return 0;
}

sub line
{
	my $self = shift;

	if(not $self->{data})
	{
		$self->{data} = 1
			if $self->{txd}->line_check($_[0]);
	}

	if($self->{data})
	{
		if($_[0] =~ /^\s*$/)
		{
			my $future = $_[0];
			$_[0] = '';
			$self->finish_block($_[0]);
			$_[0] .= $future;
			return;
		}

		my $d = $self->{txd}->line_data($_[0]);
		if(defined $d)
		{
			push(@{$self->{block}}, $d);
		}
		$_[0] = '';
	}
}

sub begin
{
	my $self = shift;

	$self->new_txd();
	$self->{block} = [];
	$self->{data} = 0;
}

sub end
{
	my $self = shift;

	$self->finish_block($_[0]);
}

sub finish_block
{
	my $self = shift;
	$self->recycle_block();

	$_[0] .= ${$self->{txd}->data_line($_)}
		for (@{$self->{block}});

	# Think about caching periods 'n' stuff and check consistency.
	$self->{block} = [];
}

# The scheme:
# shift 'abcdea' by 3 letters -> 'deabcd'
sub recycle_block
{
	my $self = shift;
	my $param = $self->{param};

	# Nothing to do for such small data sets... cannot possibly make any sense.
	# I require the end points being identical, so to have something, there must be some data in between.
	return if @{$self->{block}} < 2;

	# I support ascending and descending data.
	my $period = $self->{block}[$#{$self->{block}}][$self->{col}] - $self->{block}[0][$self->{col}];
	my $dir = $period > 0 ? +1 : -1;
	$period = abs($period);

	# Yeah, that check is not very floating-point safe.
	return unless $period > 0;

	# Shift needs to be oriented according to sorting order.
	my $shift=$param->{shift}*$dir;
	# Shift withing one period.
	$shift -= int($shift/$period)*$period;
	# ... but still, positive!
	$shift += $period if $shift < 0;
	#print STDERR "real shift: $shift\n";

	# The point of split, beginning plus shift.
	my $i = nearest_index($self->{block}[0][$self->{col}]+$dir*$shift, $dir, \@{$self->{block}});
	#print STDERR "wrap point: $i\n";
	return if ($i == 0 or $i == $#{$self->{block}}); # No need to split there.

	my @a = @{$self->{block}}; # Remember, just a bunch of references.
	# Need a copy before messing with the references.
	my @boundary = @{$a[$i]};

	# Start filling the recycled data.
	@{$self->{block}} = (@a[$i..$#a-1]);
	# The data got moved one pace back, adjust coordinate.
	$_->[$self->{col}] -= $dir*$period for (@{$self->{block}});
	# Shove in the unchanged remaining data, plus the new boundary.
	push(@{$self->{block}}, @a[0 .. $i-1]);
	push(@{$self->{block}}, \@boundary);
	# Bring the coordinates back into a sane range.
	# Am I sure that this is correct? Caring for $dir is tedious.
	# Examples: 
	if($dir*$self->{block}[0][$self->{col}] < -$period)
	{
		$_->[$self->{col}] += $dir*$period
			for (@{$self->{block}});
	}
}

sub nearest_index
{
	my ($val, $dir, $arr) = (@_);
	my $lower = $dir == +1 ? 0 : $#{$arr};
	my $upper = $dir == +1 ? $#{$arr} : 0;

	# Hacking around to get a loop that runs both ways...
	for(my $i=$lower+$dir; $i!=$upper+$dir; $i+=$dir)
	{
		if($arr->[$i][0] >= $val)
		{
			$upper = $i;
			$lower = $i-$dir;
			last;
		}
	}
 	return ($val - $arr->[$lower][0] < $arr->[$upper][0] - $val) ? $lower : $upper;
}
