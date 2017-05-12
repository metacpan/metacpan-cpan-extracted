package Text::NumericData::App::txdextrema;

use Text::NumericData::App;

use strict;
my $infostring = 'find maxima/minima in textual data files

Usage:
	txdextrema n < data.dat

The column we are interested in is simply given as a number (starting at 1) after any options; default is the second one (making sense for x-y data) or the only present one. 
The example would result in the maximum value of the third column of data.dat being printed.';

our @ISA = ('Text::NumericData::App');

sub new
{
	my $class = shift;
	my @pars =
	(
	  'minima',0,'m',
	    'look for minima (=0 means looking for maxima)'
	, 'print',0,'p',
	    'print the concerned data sets (otherwise only printing the found value)'
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
		,pipe_header => \&ignore
		,pipe_data   => \&process_data
		,pipe_end    => \&result
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
	--$self->{col};
	return 0;
}


sub init
{
	my $self = shift;
	$self->new_txd();
	$self->{ext} = undef;
	@{$self->{data}} = ();
}

sub ignore
{
	my $self = shift;
	$_[0] = '';
}

sub process_data
{
	my $self = shift;
	my $param = $self->{param};
	my $data = $self->{txd}->line_data($_[0]);
	$_[0] = '';
	return unless defined $data->[$self->{col}];

	if($self->{guesscol} and not defined $self->{col})
	{
		$self->{col} = $#{$data} < 1 ? 0 : 1;
	}
	
	if( not defined $self->{ext} or $param->{minima}
		? $data->[$self->{col}] < $self->{ext}
		: $data->[$self->{col}] > $self->{ext} )
	{
		$self->{ext} = $data->[$self->{col}];
		@{$self->{data}} = ($data) if $param->{print};
	}
	elsif($param->{print} and $data->[$self->{col}] == $self->{ext})
	{
		push(@{$self->{data}}, $data);
	}
}

sub result
{
	my $self = shift;
	my $param = $self->{param};

	return unless defined $self->{ext};

	if($param->{print})
	{
		foreach my $d (@{$self->{data}})
		{
			$_[0] .= ${$self->{txd}->data_line($d)};
		}
	}
	else
	{
		$_[0] = $self->{ext}.$self->{txd}->{config}{lineend};
	}
}
