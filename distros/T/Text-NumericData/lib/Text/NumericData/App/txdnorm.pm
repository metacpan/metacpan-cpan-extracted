package Text::NumericData::App::txdnorm;

use Text::NumericData::App;

use strict;

my $infostring = 'normalize data sets
(c) 2005 (Artistic License) by Thomas Orgis <thomas@orgis.org>
textdata version x

Usage:
	pipe | txdnorm [parameters] | pipe';

our @ISA = ('Text::NumericData::App');

sub new
{
	my $class = shift;
	my @pars =
	(
	  'to',1,'t',
	    'normalize to this (multiplication)'
	, 'from',-1,'f',
	    'normalize from this (division) - means this value in input becomes the "to" value in output, if < 0, then normalize to maximum found'
	, 'xcol',0,'x',
	    'if > 0: choose from value via given value in this column (the x data) - see pos parameter'
	, 'pos',0,'p',
	    'normalize from the value corresponding to this x value'
	, 'column',2,'c',
	    'column to normalize, starting at 1'
	, 'append',0,'a',
	    'instead of overwriting existing column, append a new one (you may want to modify titles afterwards!)'
	, 'verbose', 1, '',
	    'Give note about error conditions beyond the initial parameter checks (normalizing with zero, etc.).'
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
	unless($param->{from})
	{
		print STDERR "txdnorm: invalid from value; must be non-zero!\n";
		return -1;
	}
	print STDERR "txdnorm: you really want to make it all zero?"
		unless $param->{to};

	$param->{column} = int($param->{column}); #paranoia
	$param->{xcol} = int($param->{xcol}); #paranoia
	unless($param->{column} > 0)
	{
		print STDERR "txdnorm: invalid column!\n";
		return -1;
	}

	return 0;
}

sub process_file
{
	my $self = shift;
	my $param = $self->{param};
	my $good = 0;
	my $normcolumn = $param->{column};
	if($param->{append} and @{$self->{txd}->{Data}})
	{
		$normcolumn = $#{$self->{txd}->{Data}[0]}+2;
	}
	unless($param->{xcol} > 0)
	{
		if($param->{from} < 0)
		{
			my $max = $self->{txd}->max("abs([$param->{column}])");
			print STDERR "txdnorm: unable to perform normalisation from zero!\n"
				if($max == 0 and $param->{verbose});
			$self->{txd}->calc("[$normcolumn] = [$param->{column}] * $param->{to} / $max")
				unless $max == 0;
		}
		else
		{
			$self->{txd}->calc("[$normcolumn] = [$param->{column}] * $param->{to} / $param->{from}");
		}
		$good = 1;
	}
	else
	{
		#normalize from chosen point
		my $val = $self->{txd}->y( $param->{pos}
			, $param->{xcol}-1, $param->{column}-1 );
		if(defined $val)
		{
			print STDERR "txdnorm: unable to perform normalisation from zero!\n"
				if($val == 0 and $param->{verbose});
			$self->{txd}->calc("[$normcolumn] = [$param->{column}] * $param->{to} / $val")
				unless $val == 0;
			$good = 1;
		}
		else
		{
			print STDERR "txdnorm: found no value to start with, please try interpolation (if you already have, then you're in trouble).\n"
				if $param->{verbose};
		}
	}
	$self->{txd}->write_all($self->{out});
}

