package Text::NumericData::App::txdcalc;

use Text::NumericData::App;
use Text::NumericData::File;
use Text::NumericData::Calc qw(formula_function);
use Text::NumericData::FileCalc qw(file_calc);

use strict;

#the infostring says it all
my $infostring = 'text data calculations

Usage:
	pipe | txdcalc <options> [--] <formula;formula;formula...> [files] | pipe

It takes STDIN as primary data source and the files as secondary sources. Operation is line-wise in and out. So, this program is just a filter for data in ASCII files with quite some freedom in manipulating the data.
About formula syntax:
It is Perl, mostly. The variables (elements of corresponding rows) are denoted [n,m] in general. n is the file number (0 is the data from STDIN) and m the column (starting at 1). Short form [m] means implicitly n=0. Also there are $x or x for [0,1],  $y or y for [0,2] and $z for [0,3].

Additionally there are two arrays: A0, A1, A2, ... and C0, C1, C2, ... in the formula or references $A and $C in the plain Perl code. Both arrays are usable as you like (global scope) with the difference that @C gets initialized via the const parameter. Apart from the special syntax added here you can just use Perl to build advanced expressions, so that

	[3] = [1,2] != 0 ? [2]/[1,2] : 0

catches the division by zero. You can switch to plain Perl syntax, too (see --plainperl).

To discard a data line, place a "return 1" (or some other true --- not 0 or undefined --- value):

	return 1 if [3] != 85000;

will only include data lines with the third column being equal to 85000.
';

our @ISA = ('Text::NumericData::App');

sub new
{
	my $class = shift;

	# Note: deleted the feature of differing strictness for the several input files.
	# As I did not need it in all these years, It's apparently not worth the hassle.
	my @pars =
	(
#		'file',undef,'f','file(s) with data to be brought together with STDIN (comma-separated... you do not have any filenames with commas, do you?)',
		 'filehead',0,'F',
			'use header from file (use number starting at 1 for a file in provided list) - overriden by manual header'
		,'header',undef,'H',
			'use this header instead (\n becomes an appropriate line end, end of string by itself) - this one overrides the others'
		,'stdhead',1,'s',
			'use header from STDIN (overridden by other options)'
		,'byrow',0,'r',
			'correlate data sets simply by row number (0 / 1)'
		,'bycol',1,'c',
			'correlate data via this column in STDIN data(1..#columns)'
		,'fromcol',0,'l',
			'specify diferent columns (commalist) for correlation for each input file'
		,'lin',0,'',
			'shortcut for enforcing linear interpolation'
		,'spline',0,'',
			'shortcut for enforcing spline interpolation (overrules --line)'
		,'headcode','','C',
			'FullFun: Some code that gets eval()ed with possibility to parse/modify every head line (variable $line; line number is $num).'
		,'aftercode','','A',
			'FullFun: Some code that gets eval()ed after the input file is through (only useful together with justcalc and ignored otherwise)'
		,'beforecode','','B',
			'FullFun: Some code that gets eval()ed before input processing (yes, first B, then A, because B[efore] A[fter];-)'
		,'formula',undef,'m',
			'specify formula here or as first command line parameter'
		,'const',undef,'n',
			'specify a constant array (separated by spaces)'
		,'debug',0,'d',
			'give some info that may help debugging'
		,'justcalc',0,'j',
			'just print values of the A array after calculation and not the resulting data (for simply doing some calculation like summing, averaging...)'
		,'plainperl',0,'',
			'Use plain Perl syntax for formula for full force without confusing the intermediate parser.'
	);

	return $class->SUPER::new
	({
		 parconf     =>
		{
		   info=>$infostring
		 # default copyright
		  # default version
		}
		,pardef      => \@pars
		,pipemode    => 1
		,pipe_init   => \&preinit
		,pipe_begin  => \&init
		,pipe_header => \&process_header
		,pipe_data   => \&process_data
		,pipe_end    => \&endoffile
	});
}


sub preinit
{
	my $self = shift;
	my $param = $self->{param};

	$param->{interpolate} = 'linear' if $param->{lin};
	$param->{interpolate} = 'spline' if $param->{spline};

	if(defined $param->{header}){ $param->{stdhead} = 0; $param->{filehead} = 0; }
	elsif($param->{filehead}){ $param->{stdhead} = 0; }

	# That should return an error, shouldn't it?\
	# Changed it so.
	if(!defined $param->{formula} and !@{$self->{argv}}){ print STDERR  "That's not enough... see $0 --help\n"; return -1; }

	$self->{files} = [];
	my $form = defined $param->{formula} ? $param->{formula} : shift(@{$self->{argv}});

	#remember: on the outside col 1..cols; inside 0..cols-1 !
	unless($param->{byrow})
	{
		if($param->{bycol} < 1)
		{
			print STDERR "invalid column for correlation!\n";
			return -1;
		}
		--$param->{bycol};
	}
	$self->{fromcol} = $param->{fromcol} ? [split(',', $param->{fromcol})] : [];
	my $si = 0;

	for(@{$self->{argv}})
	{
		my $f = Text::NumericData::File->new($param, $_);
		push(@{$self->{files}}, $f);
		my $lastf = $#{$self->{files}};
		print STDERR "Warning: Got no data out of $_!\n"
			unless @{$f->{data}};
		$self->{fromcol}[$lastf] = defined $self->{fromcol}[$lastf] ? $self->{fromcol}[$lastf]-1 : $param->{bycol};
		print STDERR "warning: $_ doesn't have a column $self->{fromcol}[$lastf]\n"
			if($self->{fromcol}[$lastf] < 0 or $self->{fromcol}[$lastf] >= $self->{files}[$lastf]->columns())
	}

	if($param->{filehead} and ($param->{filehead} > @{$self->{files}} or $param->{filehead} < 0))
	{
		print STDERR "Invalid file number for header!\n";
		return -1;
	}

	# Formula function with configuration for file_calc, only row offset is changed per line.
	$self->{ff} = formula_function($form,{verbose=>$param->{debug},plainperl=>$param->{plainperl}});
	$self->{ffconf} =
	{
	  bycol  	  => $param->{bycol}
	, fromcol	  => $self->{fromcol}
	, byrow  	  => $param->{byrow}
	, skipempty   => 1 # They're skipped before, anyway ...
	, rowoffset   => 0
	};

	unless(defined $self->{ff})
	{
		print STDERR "Error in formula!\n";
		return -1;
	}
	$self->{C} = defined $param->{const} ? [split(' ', $param->{const})] : [];
	foreach my $c (@{$self->{C}})
	{
		# Another such eval ... this one really is supposed to be context-free.
		$c = eval $c;
	}
}

# Evil eval ... make it safer? Its purpose is to give endless possibilities, after all.
sub context_eval
{
	my $self = shift;
	return unless $self->{param}{$_[0]} ne '';

	my $A = $self->{A};
	my $C = $self->{C};
	eval $self->{param}{$_[0]};
}

sub init
{
	my $self = shift;
	$self->new_txd();
	$self->{row} = -1;
	$self->{num} = 0;
	$self->{A} = [];
	$self->{parheader} = $self->{param}{header};
	$self->{parfilehead} = $self->{param}{filehead};
	$self->context_eval('beforecode');
}

sub process_header
{
	my $self = shift;
	my $param = $self->{param};
	++$self->{num}; #increase head line counter
	$self->context_eval('headcode');
	$_[0] = '' unless($param->{stdhead} and not $param->{justcalc}); 

	unless($param->{justcalc})
	{
		#now we should at least know the line ending
		if(defined $self->{parheader})
		{
			$self->{parheader} =~ s/\\n/$self->{txd}{config}{lineend}/g;
			$_[0] = $self->{parheader}.$self->{txd}{config}{lineend};
			$self->{parheader} = undef;
		}
		elsif($self->{parfilehead})
		{
			$_[0] = '';
			foreach my $l (@{$self->{files}[$self->{parfilehead}-1]->{raw_header}})
			{
				$_[0] .= $l.$self->{txd}{config}{lineend};
			}
			$self->{parfilehead} = 0;
		}
	}

}

sub process_data
{
	my $self = shift;
	my $param = $self->{param};

	# Preserve empty lines that may have a meaning
	# In strict mode, though, multiple spaces may have meaning,
	# so let's have file_calc() worry about ignoring.
	if(not $param->{strict} and $_[0] =~ /^\s*$/){ return; }

	my $data = $self->{txd}->line_data($_[0]);
	$self->{ffconf}{rowoffset} = ++$self->{row};

	# Doing calculation for a fake file with one data set only.
	# This keeps the logic in one common place and also leads the
	# mind to the idea of optional caching of lines and block operation.
	# But, the semantics of one line in and one line out, immediately are
	# probably not to change.
	my $ignore = file_calc( $self->{ff}, $self->{ffconf}
	, [$data] # Don't forget: This is the actual data we work on ...
	, $self->{files}, $self->{A}, $self->{C} );

	# On error, ignore the line. Else, the returned array has
	# one entry if the line should be purposefully ignored.
	my $nothing = defined $ignore
		? @{$ignore} # == 0 normally
		: 1;

	$_[0] = ($nothing or $param->{justcalc})
		? ''
		: ${$self->{txd}->data_line($data)};
}

sub endoffile
{
	my $self = shift;
	# Prepend a line with results.
	# The line end should match input since it comes from the Text::NumericData instance.
	$_[0] = ${$self->justcalc_result()}.$_[0] if $self->{param}{justcalc};
}

sub justcalc_result
{
	my $self = shift;
	$self->context_eval('aftercode');
	return $self->{txd}->data_line($self->{A});
}
