package Text::NumericData::App::txdmean;

use Text::NumericData::App;

use strict;
my $infostring = 'find means in textual data files

Usage:
	txdmean < data.dat

should result in a line with the mean values being printed';

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
		,pipe_begin  => \&init
		,pipe_header => \&ignore
		,pipe_data   => \&process_data
		,pipe_end    => \&result
	});
}

sub init
{
	my $self = shift;

	$self->new_txd();
	$self->{mean} = [];
	$self->{ln} = 0;

	return 0;
}

sub ignore
{
	my $self = shift;
	$_[0] = '';
}

sub process_data
{
	my $self = shift;

	my $data = $self->{txd}->line_data($_[0]);
	$_[0] = '';
	return unless @{$data};

	++$self->{ln};

	if(@{$self->{mean}})
	{
		for(my $i = 0; $i <= $#{$self->{mean}}; ++$i)
		{
			$self->{mean}[$i] += $data->[$i];
		}
	}
	else
	{
		$self->{mean} = $data;
	}
}

sub result
{
	my $self = shift;

	# If no data there, nothing will happen.
	for(my $i = 0; $i <= $#{$self->{mean}}; ++$i)
	{
		$self->{mean}[$i] /= $self->{ln};
	}
	$_[0] = ${$self->{txd}->data_line($self->{mean})};
}
