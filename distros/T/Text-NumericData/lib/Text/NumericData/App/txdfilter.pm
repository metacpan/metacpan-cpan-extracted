package Text::NumericData::App::txdfilter;

use Text::NumericData::App;

use strict;

#the infostring says it all
my $infostring = 'filter textual data files

This program filters/transforms textual data files (pipe operation) concering the syntax and header stuff. The data itself is preserved. Any Parameters after options are file title and data column titles (overriding the named parameters).';

our @ISA = ('Text::NumericData::App');

sub new
{
	my $class = shift;
	my @pars =
	(
		'touchdata',1,'','touch the data lines (otherwise just copy them)',
		'touchhead',1,'','touch the header (otherwise just copy)',
		'newhead',0,'n','make completely new header',
		'comment',[],'C','comment to include between file title and column titles, lines in array',
		'headlines',undef,'H','use this fixed number of lines as header',
		'delaftercom',0,'D','delete any comment lines after data',
		'lhex','','L','regex for last header line (alternative to fdex)',
		'fdex','','F','regex for first data line (alterative to lhex)',
		'title',undef,'t','new title',
		'coltitles',[],'i','new column titles (as in "title1","title2","title3")',
		'modtitles',{},'m','modify existing titles... hash with column indices as key, in Perl: (1=>"NeSpalte",4=>"AndereSpalte")',
		'origin',0,'o','create Origin-friendly format with tab separation and coltitles as only header line and NO comment character, triggers also quote=0 and delaftercom=1',
		'data',1,'','include the data in printout',
		'head',1,'','include the header in printout',
		'history',0,'','keep old title(s) lines as historic comments (writing new overall title before, new column titles below), otherwise replace them'
	);

	return $class->SUPER::new
	({
		 parconf=>
		{
		   info=>$infostring
		 # default copyright
		  # default version
		}
		,pardef=>\@pars
		,pipemode=>1
		,pipe_init=>\&prepare
		,pipe_begin=>\&init
		,pipe_line=>\&process_line
		,pipe_end=>\&endhook
	});
}

sub prepare
{
	my $self = shift;
	my $param = $self->{param};

	if($param->{origin})
	{
		$param->{comchar} = '';
		$param->{outsep} = "\t";
		$param->{quote} = 0;
		$param->{delaftercom} = 1;
	}

	#plain command line parameters are file and column titles
	$self->{title} = @{$self->{argv}} ? shift(@{$self->{argv}}) : $param->{title};
	$self->{titles} = @{$self->{argv}} ? $self->{argv} : $param->{coltitles};
	# precompile header/data matches
	$self->{lhex} = qr/$param->{lhex}/ if $param->{lhex} ne '';
	$self->{fdex} = qr/$param->{fdex}/ if $param->{fdex} ne '';

	return 0;
}

sub init
{
	my $self = shift;
	$self->new_txd();
	#storage for old header lines
	$self->{headlines} = [];
	#counter/switch
	$self->{l} = 0;
	$self->{lasthead} = 0;
}

sub process_line
{
	my $self = shift;
	my $c = $self->{txd};
	my $param = $self->{param};
	my $pre = ''; # prepend text just before output

	if(!$self->{state}{data})
	{
		#maybe still in header
		my $is_data = $self->{lasthead} ? 1 : $c->line_check($_[0]);
		# Behaviour when both expressions are specified:
		# The first one that triggers defines beginning of data part.
		# An idea would be to intentionally skip a part between.
		# Think about that ...
		if(!$self->{lasthead} and defined $self->{lhex})
		{
			$is_data = 0;
			$self->{lasthead} = $_[0] =~ $self->{lhex};
		}
		if(defined $self->{fdex})
		{
			# possibly overriding line_check
			$is_data = $_[0] =~ $self->{fdex};
		}
		# End header on specified number of lines or when thinking that data was found.
		if( (!defined $param->{headlines} and $is_data) or (defined $param->{headlines} and ++$self->{l} > $param->{headlines}) )
		{
			#first data line found
			$self->{state}{data} = 1;

			$self->header_workout($pre);
		}
		else #collect headlines
		{
			my $h = $_[0];
			$c->make_naked($h);
			push(@{$self->{headlines}},$h);
			$_[0] = '';
		}
	}
	if($self->{state}{data})
	{
		# skip data section if so desired
		unless($param->{data})
		{
			$_[0] = '';
		}
		else
		{
			# data line processing
			# This logic is not nested right, code duplication has to go.
			unless($param->{delaftercom})
			{
				# normal handling, repeat everything unless unworthy
				if($_[0] eq $c->{config}{lineend})
				{
					$_[0] = '' if $param->{noempty};
				}
				elsif($param->{touchdata})
				{
					$_[0] = ${$c->data_line($c->line_data($_[0]))};
				}
			}
			elsif($c->line_check($_,1))
			{
				$_[0] = ${$c->data_line($c->line_data($_[0]))}
					if($param->{touchdata});
			}
			else{ $_[0] = ''; }
		}
	}
	$_[0] = $pre.$_[0] if $pre ne '';
}

sub endhook
{
	my $self = shift;
	# If there was no data, still produce a header when it was given via command line.
	$self->header_workout(@_) unless($self->{state}{data});
}

# generic helper for applying modtitles (actually, just numeric-key hash to array)
sub mod_titles
{
	my ($t,$m) = @_;
	foreach my $k (keys %{$m})
	{
		if($k =~ /^\d+$/)
		{
			$t->[$k-1] = $m->{$k};
		}
	}
}

# construct header and prepend to current line, if demanded
sub header_workout
{
	my $self = shift;
	my $param = $self->{param};
	return unless $param->{head};

	#now print header
	my $c = $self->{txd};

	unless($param->{touchhead})
	{
		my $pre = join($c->get_end(), @{$self->{headlines}});
		$pre .= $c->get_end() if $pre ne '';
		$_[0] = $pre.$_[0];
		return;
	}

	$c->{title} = $self->{title} if defined $self->{title};
	$c->{titles} = $self->{titles} if @{$self->{titles}};
	mod_titles($c->{titles}, $self->{param}{modtitles});
	my $pre = '';
	if($param->{origin})
	{
		#mangle it for Origin...
		#Origin uses "titles" in first two lines as legend text
		#since normally the same kind of data from different sources
		#is identified in a plot via the legend, any comment text 
		#provided for the file is repeated here for every column
		#looks senseless in file, makes sense in Origin
		#print STDERR "TODO: revisit Origin format ... is this really the best way?\n";
		my $titles = $c->{titles};
		foreach my $com (@{$param->{comment}})
		{
			my @car = ();
			for(my $i = 0; $i <= $#{$titles}; ++$i)
			{
				push(@car, $com);
			}
			$c->{titles} = \@car;
			$pre .= ${$c->title_line()};
		}
		#the "real" title is still there after any comments
		$c->{titles} = $titles;
		$pre .= ${$c->title_line()};
	}
	else
	{
		my $old_comments = $param->{history} ? $self->{headlines} : $c->{comments};
		#file title
		if(defined $c->{title}){ $pre .= ${$c->comment_line($c->{title})}; }
		foreach my $l (@{$param->{comment}})
		{
				$pre .= ${$c->comment_line($l)};
		}
		#old stuff
		unless($param->{newhead})
		{
			foreach my $h (@{$old_comments})
			{
				$pre .= ${$c->comment_line($h)};
			}
		}
		#only if new one is desired
		# Is that logic complete?
		$pre .= ${$c->title_line()} if (@{$c->{titles}} or @{$self->{titles}} or (keys %{$param->{modtitles}}));
	}
	$_[0] = $pre.$_[0];
}


1;
