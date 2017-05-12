package Text::NumericData::App::txdcontract;

use Text::NumericData::App;

use strict;

#the infostring says it all
my $infostring = 'contract a data file by computing the mean over n input rows to produce one output row

txdcontract 2 < 100rows.dat > 50rows.dat';

our @ISA = ('Text::NumericData::App');

sub new
{
	my $class = shift;
	my @pars = ();

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
	unless(defined $n)
	{
		print STDERR "Need n as argument!\n";
		return -1;
	}
	$self->{n} = int($n);
	unless($n>0)
	{
		print STDERR "Need n>0!\n";
		return -1;
	}

	return 0;
}

sub init
{
	my $self = shift;

	$self->new_txd();
	$self->{mean} = [];
	$self->{ln} = 0;
}

sub process_data
{
	my $self = shift;
	my $data = $self->{txd}->line_data($_[0]);
	$_[0] = '';
	return unless defined $data;

	++$self->{ln};
	for(my $i = 0; $i <= $#{$data}; ++$i)
	{
		$self->{mean}[$i] += $data->[$i];
	}
	if($self->{ln} == $self->{n})
	{
		for(my $i = 0; $i <= $#{$self->{mean}}; ++$i)
		{
			$self->{mean}[$i] /= $self->{n};
		}
		$_[0] = ${$self->{txd}->data_line($self->{mean})};
		@{$self->{mean}} = ();
		$self->{ln} = 0;
	}
}

1;
