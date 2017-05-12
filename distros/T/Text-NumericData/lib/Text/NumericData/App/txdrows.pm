package Text::NumericData::App::txdrows;

use Text::NumericData;
use Text::NumericData::Calc qw(expression_function);
use Text::NumericData::App;

use strict;

my $infostring = 'split a section of sets out of singe data file

Usage:
	pipe | txdrows -b=3 -e=10 | pipe
	pipe | txdrows \'near([1], 3.1)\' | pipe

This program extracs rows (data sets, sections, records, ...) of a numerical text file. Either this is a configured range of lines via begin/end indices or a decimation factor, or a set of rows matching a given expression on the command line.
The last example employs such an expression to match the first row that has a value near 3.1 in the first column. You could specify a third argument to near() to change the default allowed deviation. If you deal with integer values, using

	pipe | txdrows \'[1] == 3\' | pipe

is fine, too, for selecting value 3.';

our @ISA = ('Text::NumericData::App');

sub new
{
	my $class = shift;
	my @pars =
	(
		 'begin', 1, 'b',
			'begin of section'
		,'end', -1, 'e',
			'end of section (when negative: until end)'
		,'reduce', '1', 'r',
			'Redunce row count by a certain factor: Only include every ...th one. A value of 2 means rows 1,3,5... , a value of 10 means rows 1,11,21... (from the beginning).'
		,'justmatch',1,'j',
			'if an expression to match is given, select what to print out: 0 means all matches including header, >0 means just the first n matches, <0 means all matches, but no header'
		,'verbose',0,'v',
			'be verbose about things'
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
		,pipe_header => \&process_header
		,pipe_data   => \&process_data
	});
}

sub preinit
{
	my $self = shift;
	my $p = $self->{param};

	# Sanitation...
	$self->{reduce} = $p->{reduce} < 1 ? 1 : $p->{reduce};

	$self->{match} = shift(@{$self->{argv}});
	$self->{matchfun} = undef;
	$self->{matchnohead} = 0;
	if(defined $self->{match})
	{
		$self->{matchfun} = expression_function($self->{match}, $p->{verbose});
		return print STDERR "Error creating function for matching.\n" unless defined $self->{matchfun};
		$self->{matchnohead} = $p->{justmatch} != 0;
	}
	return 0;
}

sub init
{
	my $self = shift;
	$self->new_txd();
	$self->{line} = 0;
	$self->{matched} = 0;
}

sub process_header
{
	my $self = shift;
	$_[0] = '' if $self->{matchnohead};
}

sub process_data
{
	my $self = shift;
	my $p = $self->{param};
	if(defined $self->{matchfun})
	{
		if
		(
			not($p->{justmatch} > 0 and not $self->{matched} < $p->{justmatch})
			and $self->{matchfun}->([$self->{txd}->line_data($_[0])])
		){ ++$self->{matched}; }
		else{ $_[0] = ''; }
	}
	else
	{
		unless
		(
			++$self->{line} >= $p->{begin}
			and (($self->{line}-1) % $self->{reduce} == 0)
			and ($p->{end} < 0 or $self->{line} <= $p->{end})
		)
		{
			$_[0] = '';
		}
	}
}

1;
