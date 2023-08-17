package Text::NumericData::App::txdrows;

use Text::NumericData;
use Text::NumericData::Calc qw(expression_function);
use Text::NumericData::App;

use strict;

# This is just a placeholder because of a past build system bug.
# The one and only version for Text::NumericData is kept in
# the Text::NumericData module itself.
our $VERSION = '1';
$VERSION = eval $VERSION;

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
			'begin of section (above all other criteria)'
		,'end', -1, 'e',
			'end of section (when negative: until end; above all other criteria)'
		,'reduce', '1', 'r',
			'Reduce row count by a certain factor: Only include every ...th one. A value of 2 means rows 1,3,5... , a value of 10 means rows 1,11,21... (from the input).'
		,'justmatch',1,'j',
			'if an expression to match is given, select what to print out: 0 means all matches including header, >0 means just the first n matches, <0 means all matches, but no header'
		,'verbose',0,'v',
			'be verbose about things'
		,'ranges', [], 'R', 'give multiple ranges (format: "from:to", either may'
		.	' be omitted or set to negative to extend to beginning/end) inside'
		.	' the main range given by begin and end indices, this does not'
		.	' duplicate or rearrange data, just specifies an additional condition'
		.	' to include a record or not, in input order'
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
		return print STDERR "Error creating function for matching ($!).\n" unless defined $self->{matchfun};
		$self->{matchnohead} = $p->{justmatch} != 0;
	}
	$self->{ranges} = [];
	if(@{$p->{ranges}})
	{
		for(@{$p->{ranges}})
		{
			return print STDERR "Bad range: $_\n"
				unless /^\s*([+\-]?\d*)\s*:\s*([+\-]?\d*)\s*$/;
			push(@{$self->{ranges}}, [$1 ne '' ? $1 : -1, $2 ne '' ? $2 : -1]);
		}
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

# Check if given line index is inside the configured ranges,
# including reduction. Everything that works on the line index alone.
sub _chosen_line()
{
	my $self = shift;
	my $p = $self->{param};
	my $i = shift;

	return 0 # Global range first.
		unless($i >= $p->{begin} and ($p->{end} < 0 or $i <= $p->{end}));
	return 0 # Line reduction, the other simple test.
		unless(($self->{line}-1) % $self->{reduce} == 0);
	# At last, the more elaborate check of sub-ranges.
	if(@{$self->{ranges}})
	{
		for(@{$self->{ranges}})
		{
			return 1
				if($i >= $_->[0] and ($_->[1] < 0 or $i <= $_->[1]));
		}
		return 0; # There are ranges, but none contain this index.
	}
	else
	{
		return 1; # No further sub-ranges. It's in.
	}
}

sub process_data
{
	my $self = shift;
	my $p = $self->{param};
	++$self->{line};
	# Checks based on line number.
	unless($self->_chosen_line($self->{line}))
	{
		$_[0] = '';
		return;
	}
	# Additional check with match function.
	if(defined $self->{matchfun})
	{
		if
		(
			not($p->{justmatch} > 0 and not $self->{matched} < $p->{justmatch})
			and $self->{matchfun}->([$self->{txd}->line_data($_[0])])
		){ ++$self->{matched}; }
		else{ $_[0] = ''; }
	}
}

1;
