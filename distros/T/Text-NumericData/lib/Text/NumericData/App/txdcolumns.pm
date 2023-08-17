package Text::NumericData::App::txdcolumns;

use Text::NumericData::App;

use strict;

# This is just a placeholder because of a past build system bug.
# The one and only version for Text::NumericData is kept in
# the Text::NumericData module itself.
our $VERSION = '1';
$VERSION = eval $VERSION;

my $infostring = 'get specific columns out of textual data files

Usage:
	pipe | txdcolumns 3 1 | pipe

to extract the third and the first (in that order) column of input. Guess how to extract columns 2, 4 and 3;-)';

our @ISA = ('Text::NumericData::App');

sub new
{
	my $class = shift;
	my @pars =
	(
		'columns',undef,'c'
	,	'list (comma-separeted) of columns to extract - plain command line args are added to this list'
	.	' (fully specified ranges are supported, 3-5 = 3,4,5)'
	, 'title','-1','',
	    'choices for determining column indices from column titles: -1 for automatic treatment of given column values as plain indices if they are integers and as column title to match otherwise, 0: only expect numeric column indices, 1: only expect titles to match; about title matches: you give Perl regular expressions to match against the titles, you write the $bla part in m/$bla/'
	, 'debug', 0, '', 'print some stuff to stderr to help debugging'
	, 'invert', 0, 'i', 'specify columns to _omit_, not to include'
	);

	return $class->SUPER::new
	({
		 parconf =>
		{
			info=>$infostring # default version
			# default author
			# default copyright
		}
		,pardef          => \@pars
		,pipemode        => 1
		,pipe_init       => \&preinit
		,pipe_begin      => \&init
		,pipe_header     => \&process_header
		,pipe_first_data => \&process_first_data
		,pipe_data       => \&process_data
	});
}

sub preinit
{
	my $self = shift;
	my $param = $self->{param};

	$self->{pcols} = [];
	my @pcols = defined $param->{columns}
		? (split(/\s*,\s*/, $param->{columns}))
		: ();
	for(@pcols, @{$self->{argv}})
	{
		if(/^(\d+)-(\d+)$/)
		{
			my $incr = $1 < $2 ? +1 : -1;
			for(my $c = $1; $c != $2+$incr; $c+=$incr)
			{
				push(@{$self->{pcols}}, $c);
			}
		}
		else
		{
			push(@{$self->{pcols}}, $_);
		}
	}
	#print STDERR "You really want NO data?\n" unless @pcols;
	return 0;
}

sub init
{
	my $self = shift;

	$self->new_txd();
	$self->{cols} = [];
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

# This is the ugly part, deriving the columns and column headers to use.
sub process_first_data
{
	my $self = shift;
	my $param = $self->{param};

	if(not $param->{title})
	{
		@{$self->{cols}} = @{$self->{pcols}};
	}
	else
	{
		@{$self->{cols}} = ();
		for my $cc (@{$self->{pcols}})
		{
			if($param->{title} == 1 or not $cc =~ /^\d+$/)
			{
				my $nc = 0; # invalid column
				for my $i (0..$#{$self->{txd}->{titles}})
				{
					# No /o modifier, that would relate to the first value of $cc only!
					if($self->{txd}->{titles}[$i] =~ m/$cc/)
					{
						$nc = $i+1;
						last;
					}
				}
				push(@{$self->{cols}}, $nc);
			}
			else{ push(@{$self->{cols}}, $cc); }
		}
	}
	my $i = 0;
	foreach my $n (@{$self->{cols}})
	{
		--$n;
		# If we don't have titles, detecting bad columns is not possible in advance.
		# (could only guess based on first data set, which may not be complete)
		die "Bad column ($self->{pcols}[$i])!\n"
			if
			(
				not $param->{fill} and
				(
					$n < 0 or
					(
						@{$self->{txd}->{titles}}
						and $n > $#{$self->{txd}->{titles}}
					)
				)
			);
		++$i;
	}

	print STDERR "Decided on column indices: @{$self->{cols}}.\n"
		if $param->{debug};

	if($#{$self->{txd}->{titles}} > -1)
	{
		print STDERR "Got actual titles, extracting.\n"
			if $param->{debug};
		return $self->{txd}->title_line(
			$param->{invert} ? undef : $self->{cols}
		,	$param->{invert} ? $self->{cols} : undef );
	}
	else{  return \$self->{sline}; }
}

# The actual extraction of columns is a piece of cake.
sub process_data
{
	my $self = shift;
	my $include = $self->{param}{invert} ? undef : $self->{cols};
	my $exclude = $self->{param}{invert} ? $self->{cols} : undef;
	$_[0] = ${$self->{txd}->data_line(
		$self->{txd}->line_data($_[0]), $include, $exclude )};
}
