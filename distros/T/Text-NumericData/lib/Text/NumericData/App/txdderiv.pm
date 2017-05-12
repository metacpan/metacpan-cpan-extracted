package Text::NumericData::App::txdderiv;

use Text::NumericData::App;
# Not using Math::Derivative, central difference mid-interval suits me better.
# Actually changing my mind there ... computing on the points again.
# You got the dualgrid option now.

use strict;

#the infostring says it all
my $infostring = "compute derivative of data sets using central differences

Usage:
	$0 [parameters] [ycol|xcol ycol [ycol2 ...]] < data.dat

You can provide the x and y column(s) to work on on the command line as plain numbers of as values for the --xcol and --ycol parameters. The latter are overridden by the former.";

our @ISA = ('Text::NumericData::App');

sub new
{
	my $class = shift;
	my @pars = 
	(
		 'xcol',1,'x','abscissa column'
		,'ycol',[2],'y','ordinate column, or columns as array'
		,'dualgrid',0,'','define the derivative on points between the initial sampling points, thusly creating a new grid; otherwise, the central differences are computed on each input point with its neighbours'
		,'append',0,'','do not replace data with the derivatives, append them as additional columns instead (only works if dual-grid mode is off)'
		,'sort',1,'','sort the data according to x column (usually desirable unless you got a specific order wich should be monotonic)'
	);
	return $class->SUPER::new
	({
		 parconf=>
		{
			 info=>$infostring # default version
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
	my $p = $self->{param};

	return $self->error("Append mode and dualgrid don't mix.")
		if($p->{append} and $p->{dualgrid});

	if(@{$self->{argv}})
	{
		if(@{$self->{argv}} == 1)
		{
			$p->{ycol} = [shift @{$self->{argv}}];
		}
		else
		{
			$p->{xcol} = shift @{$self->{argv}};
			@{$p->{ycol}} = @{$self->{argv}};
		}
	}

	return $self->error("Bad x column index!")
		unless(valid_column([$p->{xcol}]));
	return $self->error("Bad y column index/indices!")
		unless(valid_column($p->{ycol}));

	# Translate to plain 0-based indices.
	$self->{xi} = $p->{xcol}-1;
	$self->{yi} = [@{$p->{ycol}}];
	for(@{$self->{yi}}){ --$_; }

	return 0;
}


sub process_file
{
	my $self = shift;
	my $p = $self->{param};
	my $txd = $self->{txd};

	# sort out titles
	my @cidx = ($p->{xcol}-1);
	my $cols = $txd->columns();
	unless($cols > 0)
	{
		print STDERR "No data columns?\n";
		$txd->write_all($self->{out});
		return;
	}

	my @derivtitles;
	for my $y (@{$p->{ycol}})
	{
		push(@derivtitles, derivtitle($txd->{titles}[$y-1], $y));
		push(@cidx, $y-1);
	}

	if(@{$txd->{titles}})
	{
		if($p->{append})
		{
			$txd->{titles}[$cols-1] = '' unless defined $txd->{titles}[$cols-1];
			push(@{$txd->{titles}}, @derivtitles);
		}
		else
		{
			my $xt = $txd->{titles}[$p->{xcol}-1];
			@{$txd->{titles}} = ($xt, @derivtitles);
		}
	}

	if(@{$txd->{raw_header}}){ $txd->write_header($self->{out}); }
	if(@{$txd->{titles}}){ print {$self->{out}} ${$txd->title_line()}; }

	# compute derivatives, after sorting data
	$txd->sort_data([$p->{xcol}-1], [0]) if $p->{sort};
	my $diffdata = $p->{dualgrid}
		? central_diff_dualgrid($txd->{data}, $self->{xi}, $self->{yi})
		: central_diff_samegrid($txd->{data}, $self->{xi}, $self->{yi});
	if($p->{append})
	{
		for(my $i=0; $i<=$#{$diffdata}; ++$i)
		{
			shift(@{$diffdata->[$i]});
			push(@{$txd->{data}[$i]}, @{$diffdata->[$i]});
		}
	}
	else
	{
		$txd->{data} = $diffdata;
	}
	$txd->write_data($self->{out});
}

# Perhaps a general helper in TextData for validation of input.
sub valid_column
{
	my ($cols, $max) = @_;
	return 0 if (grep {$_ != int($_) or $_ < 1} @{$cols});
	return 0 if (defined $max and grep {$_ > $max} @{$cols});
	return 1;
}

# local functions, not methods

# f'(x) = f(x+h)-f(x-h)/2h + O(h^2)
sub central_diff_dualgrid
{
	my ($data, $xi, $yi) = @_;
	my @diff;
	for(my $i=1; $i<=$#{$data}; ++$i)
	{
		my $prev = $data->[$i-1];
		my $next = $data->[$i];
		# treat empty lines as separations
		if(not @{$prev} or not @{$next})
		{
			push(@diff, []);
			# Really skip it if nothing follows.
			++$i unless not @{$next};
			next;
		}
		my $dx = $next->[$xi] - $prev->[$xi];
		next if not $dx > 1e-12; # some safety precaution, better tunable?
		my $invdx = 1./$dx;
		my @point = ( 0.5*($prev->[$xi]+$next->[$xi]) );
		for(@{$yi})
		{
			push(@point, $invdx*($next->[$_]-$prev->[$_]));
		}
		push(@diff, \@point);
	}
	return \@diff;
}

# f'(x) = (v^2 f(x+w) - (v^2-w^2) f(x) - w^2 f(x-v)) / (wv^2+vw^2) + O(v^3w^2/(wv^2+vw^2)) + O(w^3v^2/(wv^2+vw^2))
#       = (f(x+w) - (1-(w/v)^2) f(x) - (w/v)^2 f(x-v)) / w(1+w/v)  + O(v^3w^2/(wv^2+vw^2)) + O(w^3v^2/(wv^2+vw^2))
# you better have some distance between the points, no precaution here
sub central_diff_samegrid
{
	my ($data, $xi, $yi) = @_;
	my @diff;
	# Cannot do anything with a single value ... well, could call it a zero.
	return \@diff if(@{$data} < 2);

	for(my $i=0; $i<=$#{$data}; ++$i)
	{
		my $this = $data->[$i];
		my $prev = $i > 0 ? $data->[$i-1] : undef;
		my $next = $i < $#{$data} ? $data->[$i+1] : undef;
		my @point = ( $this->[$xi] );
		# empty line, treat separate pieces
		for ($prev, $this, $next)
		{
			$_ = undef if(defined $_ and not @{$_});
		}
		unless(defined $this)
		{
			push(@diff, []);
			next;
		}
		my $v = defined $prev ? $this->[$xi] - $prev->[$xi] : undef;
		my $w = defined $next ? $next->[$xi] - $this->[$xi] : undef;

		if(not defined $prev)
		{
			# f'(x) = (f(x+w)-f(x)) / w
			my $invdx = 1./$w;
			for(@{$yi})
			{
				push(@point, $invdx*($next->[$_]-$this->[$_]));
			}
		}
		elsif(not defined $next)
		{
			# f'(x) = (f(x+w)-f(x)) / w
			my $invdx = 1./$v;
			for(@{$yi})
			{
				push(@point, $invdx*($this->[$_]-$prev->[$_]));
			}
		}
		else
		{
			my $wbyv = $w/$v;
			my $invdx = 1./($w*(1+$wbyv));
			my $thisweight = 1-$wbyv**2;
			my $prevweight = $wbyv**2;
			for(@{$yi})
			{
				push(@point, $invdx*($next->[$_] - $thisweight*$this->[$_] - $prevweight*$prev->[$_]));
			}
		}
		push(@diff, \@point);
	}
	return \@diff;
}

sub derivtitle
{
	my $ot = shift;
	my $col = shift;
	return 'd('.(defined $ot ? $ot : "col$col").')';
}
