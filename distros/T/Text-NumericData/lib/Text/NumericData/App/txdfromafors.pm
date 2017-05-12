package Text::NumericData::App::txdfromafors;

use Text::NumericData::App;

use strict;

my $infostring = 'Hacky tool to convert AFORS-HET (photovoltaic cell simulation) output to usual columns of textual data. Filters STDIN to STDOUT. Due to AFORS-HET appending data to the end, the whole input is buffered, but that should not be an issue for the moderate size of the 1D data.';

our @ISA = ('Text::NumericData::App');

sub new
{
	my $class = shift;
	my @pars =
	(
	  'title', 'AFORS-HET data', 't',
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
		,pipe_end    => \&finish
	});
}

my $head = 0;
my $data = 1;
my $post = 2;

sub init
{
	my $self = shift;
	$self->{place} = $head;
	$self->{data}  = [];
	$self->{com}   = [];
	$self->{titlesets} = [];
}

# Collect in advance.
sub process_line
{
	my $self = shift;

	$_[0] =~ s:[\r\n]::g;
	if($self->{place} == $head)
	{
		# first three lines containt title sets
		if($_[0] =~ /^[\+\-\d]/){ $self->{place} = $data; }
		else{ push(@{$self->{titlesets}}, [split("\t", $_[0])]); }
	}

	if($self->{place} == $data)
	{
		if($_[0] =~ /^\s*$/)
		{
			$self->{place} = $post;
			$_[0] = ''; return;
		}
		$_[0] =~ s:,:.:g;
		push(@{$self->{data}}, [split("\t", $_[0])]);
	}

	if($self->{place} == $post)
	{
		push(@{$self->{com}}, $_[0]);
	}
	$_[0] = '';
}

# It's a bit nasty to push all in one string, but heck, it's
# not that we are talking about gibibytes.
sub finish
{
	my $self = shift;
	my $param = $self->{param};
	my $txd = Text::NumericData->new({'separator'=>"\t", 'comment'=>'#'});

	# output of collected data
	$_[0] = ${$txd->comment_line($param->{title})};
	for my $c (@{$self->{com}})
	{
		$_[0] .= ${$txd->comment_line($c)};
	}
	# Print the titles in reverse, so that txd stuff picks up the first, most definite, title set.
	while(@{$self->{titlesets}})
	{
		$txd->{titles} = pop(@{$self->{titlesets}});
		$_[0] .= ${$txd->title_line()};
	}
	# There can be re-iterations forth and back. Bring it in order.
	# Also, result files aren't ordered along spatial dimension.
	my $sortcol = 0;
	$sortcol = 1
		if $txd->{titles}[1] =~ /^x/;
	@{$self->{data}} = sort {$a->[$sortcol] <=> $b->[$sortcol]} @{$self->{data}};
	for my $d (@{$self->{data}})
	{
		$_[0] .= ${$txd->data_line($d)};
	}
}
