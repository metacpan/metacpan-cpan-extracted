package Text::NumericData::App::txdfromtcad;

use Text::NumericData::App;

use strict;

my $infostring = 'Hacky tool to convert DF-ISE xyplot data to usual text data. Filters STDIN to STDOUT. The parser is not very smart, it is modelled exactly after the format that TCAD produces.';

our @ISA = ('Text::NumericData::App');

sub new
{
	my $class = shift;
	my @pars =
	(
	  'title', 'some TCAD data', 't',
	    'Provide a title for the data set.'
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
		,pipe_begin  => \&init
		,pipe_line   => \&process_line
	});
}


my $void = 0;
my $info = 1;
my $data = 2;
my $past = 3;

sub init
{
	my $self = shift;
	$self->{place} = $void;
	$self->{gottype} = 0;
	$self->{indatasets} = 0;
	$self->{cols} = 0;
	$self->{data} = [];
}

sub process_line
{
	my $self = shift;

	if($self->{place} == $void)
	{
		if($_[0] =~ /^Info\s*\{$/){ $self->{place} = $info; }
		elsif($_[0] =~ /^Data\s*\{$/){ $self->{place} = $data; }

		$_[0] = '';
		return;
	}
	if($self->{place} == $info)
	{
		if($_[0] =~ /^\s*type\s*=\s*xyplot$/){ $self->{gottype} = 1; }
		elsif($_[0] =~ /^\s*datasets\s*=\s*\[(.*)$/)
		{
			$self->add_datasets($1);
		}
		elsif($self->{indatasets})
		{
			$self->add_datasets($_[0]);
		}
		elsif($_[0] =~ /\}/)
		{
			$_[0]  = ${$self->{txd}->CommentLine(\$self->{param}{title})};
			$_[0] .= ${$self->{txd}->TitleLine()};
			$self->{cols} = @{$self->{txd}->{titles}};
			$self->{place} = $void;
			print STDERR "Did not find the proper file type (wanted xyplot)!\n" unless $self->{gottype};
			print STDERR "Need some columns!\n" unless $self->{cols} > 0;
		}
	}
	elsif($self->{place} == $data)
	{
		$_[0] =~ s/[\012\015]+$//;
		$_[0] =~ s/^\s*//;

		if($_[0] =~ /^\}$/)
		{
			# This should be the end.
			$self->{place} = $past;
			$_[0] = '';
			print STDERR "There is data left! (@{$self->{data}})\n"
				if(@{$self->{data}});
			return;
		}

		# Got a data line, add.
		push(@{$self->{data}}, split(/\s+/, $_[0]));

		# Write out full blocks.
		$_[0] = '';
		while(@{$self->{data}} >= $self->{cols})
		{
			my @linedata = splice(@{$self->{data}}, 0, $self->{cols});
			$_[0] .= ${$self->{txd}->data_line(\@linedata)};
		}
	}
}

sub add_datasets
{
	my $self = shift;

	$_[0] =~ s/[\012\015]+$//;

	if($_[0] =~ /^\s*(|.*\S)\s*\]$/){ $_[0] = $1; $self->{indatasets} = 0; }
	else{ $self->{indatasets} = 1; }
	# Hack!
	$_[0] =~ s:^\s*"::;
	$_[0] =~ s:"\s*$::;
	push(@{$self->{txd}->{titles}}, split(/"\s+"/, $_[0]));
}
