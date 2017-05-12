package Text::NumericData::App::txdbaseline;

use Text::NumericData::App;

use strict;

#the infostring says it all
my $infostring = 'shift a data set down to have the baseline at zero, including optional limiting of undershoots

Orginal motivation was correcting of measured optical spectra for an offset inherent in the measurement apparatus.';

our @ISA = ('Text::NumericData::App');


sub new
{
	my $class = shift;
	my @pars =
	(
		'xcol',1,'x','the x column (i.e. wavelength)',
		'ycol',2,'y','the y column (i.e. intensity)',
		'begin',0,'b','begin of baseline interval',
		'end',1,'e','end of baseline interval',
		'lowest',0,'l','take the ... lowest values instead of interval',
		'positive',0,'p','cut values below zero (making them zero; leaving only non-negative numbers)'
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
		,filemode=>1
		,pipemode=>1
		,pipe_init=>\&prepare
		,pipe_file=>\&process_file
	});
}

sub prepare
{
	my $self = shift;
	my $param = $self->{param};
	for('xcol','ycol')
	{
		$param->{$_} = int($param->{$_}); #paranoia
		return $self->error('Invalid column!') unless $param->{$_} > 0;
	}
	return $self->error('Negative number of values???') if $param->{lowest} < 0;
}

sub process_file
{
	my $self = shift;
	my $param = $self->{param};
	my $mean;
	unless($param->{lowest} > 0)
	{
		#calculate mean over interval
		$mean = $self->{txd}->mean($param->{ycol}-1, $param->{xcol}-1, $param->{begin}, $param->{end});
	}
	else
	{
		#calculate mean over lowest values
		my $y = $param->{ycol}-1;
		my $d = $self->{txd}->get_sorted_data($y);
		#the n lowest values are in the n first elements of @{$d}
		my $count = 0;
		foreach my $i (@{$d})
		{
			$mean += $i->[$y];
			last if ++$count == $param->{lowest};
		}
		$mean /= $count if $count > 0;
	}
	#substract mean
	if(defined $mean)
	{
		my $formula = '['.$param->{ycol}.'] -= '.$mean;
		$formula .= '; ['.$param->{ycol}.'] = 0 if ['.$param->{ycol}.'] < 0' if $param->{positive};
		$self->{txd}->calc($formula) or die "Error with calculation!\n";
	}
	$self->{txd}->write_all($self->{out});
}

1;
