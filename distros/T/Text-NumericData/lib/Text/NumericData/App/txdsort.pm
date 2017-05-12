package Text::NumericData::App::txdsort;

use Text::NumericData::App;

use strict;

#the infostring says it all
my $infostring = 'sorting of text data

Usage:
	pipe | txdsort [parameters] | pipe

You can sort for multiple columns, in order and down- or upwards for each column.';

our @ISA = ('Text::NumericData::App');

sub new
{
	my $class = shift;
	my @pars =
	(
	  'col',1,'c',
	  	'the column(s) concerned (first is 1, comma separated list of integers for multi-stage sorting)'
	, 'down',0,'d',
	    'sort descending; normal mode is ascending; may be also comma-separated list of 0 or 1 according to col value'
	, 'scan',0,'',
	    'Introduce empty lines after each block of the last sorting column (when it starts from a smaller value again). That is for creating "scans" for gnuplot pm3d mode.'
	);
	return $class->SUPER::new
	({
		 parconf=>
		{
			 info=>$infostring # default version,
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
	my $param = $self->{param};

	$self->{cols} = [split('\s*,\s*', $param->{col})];
	$self->{down} = [split('\s*,\s*', $param->{down})];

	$self->{maxcol} = 0; # 1-based maximum column value
	for(my $i = 0; $i<=$#{$self->{cols}}; ++$i)
	{
		$self->{cols}[$i] = int($self->{cols}[$i]);
		unless($self->{cols}[$i] > 0)
		{
			print STDERR "txdsort: invalid column: $self->{cols}[$i]!\n";
			return -1;
		}
		$self->{maxcol} = $self->{cols}[$i] if $self->{cols}[$i] > $self->{maxcol};
		--$self->{cols}[$i]; # from here on normal array indices
		$self->{down}[$i] = 0
		unless defined $self->{down}[$i];
	}
	unless(@{$self->{cols}})
	{
		print STDERR "txdsort: Need some columns!\n";
		return -1;
	}

	# possible cache of sort function
	# It should really be generated just once, without side effects.
	$self->{sortfunc} = undef;

	return 0;
}

sub process_file
{
	my $self = shift;
	my $param = $self->{param};
	my $file = $self->{txd};

	if($file->columns() < $self->{maxcol})
	{
		print STDERR "txdsort: Error: File doesn't have enough columns for that sort (".$file->columns()." vs. $self->{maxcol}).\n";
	}
	else
	{
		$self->{sortfunc} = $file->sort_data($self->{cols}, $self->{down}, $self->{sortfunc});
	}
	$file->write_header($self->{out});
	if($param->{scan})
	{
		my $lend = $file->get_end();
		my $lastv = undef;
		my $col   = $self->{cols}[$#{$self->{cols}}];
		my $down  = $self->{down}[$#{$self->{cols}}];
		foreach my $l (@{$file->{data}})
		{ # Print the lines, watchout for scan border.
			my $newv = $l->[$col];
			if(defined $lastv)
			{
				print {$self->{out}} "$lend"
					if(($down and $newv > $lastv) or (not $down and $newv < $lastv));
			}
			$lastv = $newv;
			print {$self->{out}} ${$file->data_line($l)};
		}
	}
	else
	{
		$file->write_data($self->{out});
	}
}

1;
