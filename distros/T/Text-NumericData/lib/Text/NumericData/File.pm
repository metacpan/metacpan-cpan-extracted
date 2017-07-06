package Text::NumericData::File;

# Document and properly test the pipe stuff!
# Think about replacing MaxInterval by something more generic (sorted index according to given expression)

#textdata version x
#see POD below!

use Text::NumericData::Calc qw(linear_value formula_function expression_function);
use Text::NumericData;
use Text::ASCIIPipe;
use sort 'stable';

# This is just a placeholder because of a past build system bug.
# The one and only version for Text::NumericData is kept in
# the Text::NumericData module itself.
our $VERSION = '1';
$VERSION = eval $VERSION;

our @ISA = ('Text::NumericData');

# interpolation types
my $none   = 0;
my $linear = 1;
my $spline = 2;

our %help =
(
  interpolate => 'use interpolation inter-/extrapolation for correlation of data sets (choose linear or spline, or 0 for switching it off)'
);

our %defaults =
(
  interpolate => 'linear'
);

sub new
{
	my $class = shift;
	my $config = shift;
	my $self = $class->SUPER::new($config);
	$self->{in_file} = shift;
	if(defined $config->{interpolate} and $config->{interpolate} eq 'spline')
	{
		require Math::Spline;
		$self->{intmethod} = $spline;
	}
	elsif(defined $config->{interpolate} and not $config->{interpolate})
	{
		$self->{intmethod} = $none;
	}
	else{ $self->{intmethod} = $linear; }

	$self->{config}{pipemode} = $config->{pipemode}
		if(defined $config->{pipemode});

	if(defined $self->{in_file})
	{
		$self->read_all();
	}
	return $self;
}

sub init
{
	#not touching in_file! this is only handled by Read
	#as is out_file!
	my $self = shift;
	$self->SUPER::init();
	$self->{config}{indexformat} = '%6E' unless defined $self->{config}->{indexformat};
	$self->{config}{extrapol} = 1 unless defined $self->{config}{extrapol};
	$self->{data} = [];
	$self->{records} = 0;
	$self->{data_index} = [];
	$self->{sorted_data} = [];
	$self->{raw_header} = [];
	$self->{buffer} = ""; #containing the raw lines read by readhead (the'd be lost from stdin otherwise)
	$self->{splines} = [];
	$self->{splinex} = undef;
}

sub read_head
{
	my $self = shift;
	return $self->read_all($_[0], 1);
}

# Return values mimicking Text::ASCIIPipe::pull_file.
# <0: failure
#  0: successful, but nothing more to expect
# >0: successful, more could be there
sub read_all
{
	my ($self, $infile, $justhead) = @_;
	$self->init(); #do we really want full init?
	$self->{in_file} = $infile if defined $infile;

	my $handle;

	if(ref $self->{in_file}){ $handle = $self->{in_file}; }
	elsif(not defined $self->{in_file} or $self->{in_file} eq ''){ $handle = \*STDIN; }
	else{ open($handle, $self->{in_file}) or return 0; }

	my $data = 0;
	binmode($handle);
	my $l;
	$self->{buffer} = '';

	my $state;
	while(defined ($state = Text::ASCIIPipe::fetch($handle, $l)))
	{
		if($state == $Text::ASCIIPipe::line)
		{
			if(!$data)
			{
				$self->{buffer}.= $l if($justhead);
				if($self->line_check(\$l))
				{
					last if $justhead;
					$data = 1;
				}
				else
				{
					$self->make_naked($l); 
					push(@{$self->{raw_header}}, $l);
				}
			}
			if($data)
			{
				my $da = $self->line_data($l);
				if(defined $da)
				{
					push(@{$self->{data}}, $da);
					++$self->{records} if @{$da}; # count non-empty records
				}
			}
		}
		else
		{
			# If there is no prior decision, this enables pipe control codes on possibly following write operations.
			$self->{config}{pipemode} = 1 unless defined $self->{config}{pipemode};
			# anything but line and begin is an end
			last if $state != $Text::ASCIIPipe::begin;
		}
	}

	# Empty files aren't an error, or are they?
	# All fine: Loop ended with orderly file end marker.
	return  1 if(defined $state and $state != $Text::ASCIIPipe::allend);
	# Ended on EOF (or some esoteric error we still treat as such),
	# as there was no allend or error before that, just assume normal end of things.
	return  0 if(not defined $state);
	# If we hit allend, we did not stop with an orderly file end,
	# so must assume we got nothing at all.
	return -1; # if($state == allend) is already implied
}

# After reading Data, intialize interpolation.
sub prepare_splines
{
	my $self = shift;
	my $x = shift;

	$self->{splines} = [];
	$self->{splinex} = undef;
	my $i = 0;
	my @x;
	my @data; # the more effective data structe
	for my $d (@{$self->{data}})
	{
		# collect data, omitting duplicates
		next if grep {$_ == $d->[$x]} @x;
		push(@x, $d->[$x]);
		for(my $j = 0; $j <= $#{$d}; ++$j)
		{
			$data[$j][$i] = $d->[$j];
		}
		++$i;
	}
	die "Bad spline column index.\n" if($x < 0 or $x > $#data);

	$self->{splinex} = $x;

	# Not caring for undefined pieces of data, does Math::Spline care?
	for(my $j = 0; $j <= $#data; ++$j)
	{
		$self->{splines}[$j] = Math::Spline->new(\@x, $data[$j]);
	}
}

sub SplineY
{
	my $self = shift;
	my $val = shift;
	my $x = shift;
	my $y = shift;
	$x = 0 unless defined $x;
	$y = 1 unless defined $y;
	$self->prepare_splines($x) unless(defined $self->{splinex} and $self->{splinex} == $x);

	return $self->{splines}[$y]->evaluate($val);
}

sub spline_set
{
	my $self = shift;
	my $val = shift;
	my $x = shift;
	$x = 0 unless defined $x;
	$self->prepare_splines($x) unless(defined $self->{splinex} and $self->{splinex} == $x);

	my @set;
	for my $s (@{$self->{splines}})
	{
		push(@set,  $s->evaluate($val));
	}

	return \@set;
}

#compute_index(\arrayofcols)
sub compute_index 
{
	my $self = shift;
	my $ar = shift;
	my $zahl = $self->{config}->{numregex};
	$ar = [0] unless defined $ar;
	foreach my $c (@{$ar}){ $self->{data_index}->[$c] = {};}
	foreach my $d (@{$self->{data}})
	{
		foreach my $c (@{$ar})
		{
			my $key = $d->[$c] =~ /$zahl/ ? sprintf($self->{config}->{indexformat}, $d->[$c]) : $d->[$c];
			$self->{data_index}->[$c]->{$key} = $d unless defined $self->{data_index}->[$c]->{$key};
		}
	}
}

#(col)
sub compute_sorted_index
{
	my $self = shift;
	my $xl = shift;
	$xl = [0] unless defined $xl;
	#compute any missing indices
	my @l = ();
	foreach my $x (@{$xl}){	push(@l, $x) unless defined $self->{data_index}->[$x]; }
	$self->compute_index(\@l);
	#now sort all concerned indices
	foreach my $x (@{$xl})
	{
		$self->{sorted_data}->[$x] = [];
		foreach my $k (sort {$a <=> $b} keys %{$self->{data_index}->[$x]})
		{
			push(@{$self->{sorted_data}->[$x]}, $self->{data_index}->[$x]->{$k});
		}
	}
}


sub write_data
{
	my $self = shift;
	my $handle = shift;
	my $selection = shift;
	for(my $i = 0; $i <= $#{$self->{data}}; ++$i)
	{
		print $handle ${$self->data_line($self->{data}->[$i],$selection)};
	}
	return 1; # real error checking?
}

#Write(file, columns)
#maybe adding limits in future...
sub write_all
{
	my $self = shift;
	my $file = shift;
	my $selection = shift;
	$self->{out_file} = $file if defined $file;
	my $handle;
	if(ref $self->{out_file}){ $handle = $self->{out_file}; }
	elsif(not defined $self->{out_file} or $self->{out_file} eq ''){ $handle = STDOUT; }
	else{ open($handle, '>', $self->{out_file}) or return 0; }
	binmode($handle);

	Text::ASCIIPipe::file_begin($handle) if($self->{config}{pipemode});
	#header
	$self->write_head($handle, $selection);
	#data
	$self->write_data($handle, $selection);
	Text::ASCIIPipe::file_end($handle) if($self->{config}{pipemode});
	return 1; # real error checking?
}

# An inconsistency in first release was write_header, not write_head,
# as it matches read_head. Providing this wrapper now.
sub write_header
{
	my $self = shift; # No real need to shift here, but keeping in style.
	return $self->write_head(@_);
}

sub write_head
{
	my $self = shift;
	my $handle = shift;

	my $selection = shift;
	# If there is no old raw header, do a new one automaticaly.
	if(@{$self->{raw_header}})
	{
		foreach my $h (@{$self->{raw_header}})
		{
			print $handle ${$self->comment_line($h)};
		}
		if(defined $selection)
		{
			print $handle ${$self->title_line($selection)};			
		}
	}
	else
	{
		return $self->write_new_header($handle,$selection);
	}
	return 1;
}

sub write_new_header
{
	my $self = shift;
	my $handle = shift;
	my $selection = shift;
	print $handle ${$self->comment_line(\$self->{title})} if defined $self->{title};
	foreach my $c (@{$self->{comments}}){ print $handle ${$self->comment_line(\$c)}; }
	print $handle ${$self->title_line($selection)};			
	return 1;
}

sub set_of_noint
{
	my $self = shift;
	my $value = shift;
	my $zahl = $self->{config}->{numregex};
	$value = sprintf($self->{config}->{indexformat}, $value) if $value =~ /$zahl/;
	my $x = shift;
	$x = 0 unless defined $x;
	defined $self->{data_index}->[$x] or $self->compute_index([$x]);
	return $self->{data_index}->[$x]->{$value};	
}

sub set_of
{
	my $self = shift;
	#the easy way
	my $set = $self->set_of_noint(@_);
	return $set
		if (defined $set or $self->{intmethod} == $none);

	#so, we got to do some Work;
	my $val = shift;
	my $x = shift;
	$x = 0 unless defined $x;
	if($self->{intmethod} == $spline)
	{
		return $self->spline_set($val, $x);
	}
	#find suitable data value pairs for interpolation
	my $sets = $self->neighbours($val, $x);
	return undef unless defined $sets and $#{$sets} == 1;
	#compute
	my @set = ();

	for(my $y = 0; $y <= $#{$sets->[0]}; ++$y)
	{
		if($y != $x)
		{
			push(@set, linear_value($val, [$sets->[0][$x], $sets->[1][$x]], [$sets->[0][$y],$sets->[1][$y]]));
		}
		else{ push(@set, $val); }
	}
	
	return \@set;
}

sub y_noint
{
	my $self = shift;
	my $val = shift;
	my $x = shift;
	my $y = shift;
	$x = 0 unless defined $x;
	$y = 1 unless defined $y;
	my $set = $self->set_of($val,$x);
	return defined $set ? $set->[$y] : undef;
}


sub y
{
	my $self = shift;
	#the easy way
	my $y = $self->y_noint(@_);
	return $y
		if (defined $y or $self->{intmethod} == $none);

	#so, we got to do some Work;
	my $val = shift;
	my $x = shift;
	$y = shift;
	$x = 0 unless defined $x;
	$y = 1 unless defined $y;
	if($self->{intmethod} == $spline)
	{
		return $self->spline_y($val, $x, $y);
	}
	#find suitable data value pairs for interpolation
	my $sets = $self->neighbours($val, $x);
	return undef unless defined $sets and $#{$sets} == 1;
	#compute
	#print STDERR "Sets: ";
	#for(@{$sets}){ print STDERR "(@{$_}) "; }
	#print STDERR "\n";
	return linear_value($val, [$sets->[0][$x], $sets->[1][$x]], [$sets->[0][$y],$sets->[1][$y]]);
}

#it should be configurable wheter extrapolation is acceptable

sub neighbours
{
	my $self = shift;
	my $val = shift;
	my $x = shift;
	
	my $n = undef;
	my $e = undef;

	unless($self->{config}{orderedint})
	{
		defined $self->{sorted_data}->[$x] or $self->compute_sorted_index([$x]);
		return undef unless $#{$self->{sorted_data}->[$x]} > 0; #senseless when not at least two points there

		foreach my $v (@{$self->{sorted_data}->[$x]})
		{
			$n = $e;
			$e = $v;
			if($v->[$x] > $val and defined $n){ last; }
		}
	}
	else
	{
		if(defined $self->{data}[0] and $self->{data}[0][$x] < $val)
		{
			foreach my $v (@{$self->{data}})
			{
				$n = $e;
				$e = $v;
				if($v->[$x] > $val and defined $n){ last; }
			}
		}
		else
		{
			foreach my $v (@{$self->{data}})
			{
				$n = $e;
				$e = $v;
				if($v->[$x] < $val and defined $n){ last; }
			}
		}
	}
	return undef unless defined $n; #catches both  empty array and one-element-array
	unless($self->{config}{extrapol})
	{
		#check if we have left and right neighbour
		return undef unless (($n->[$x] <= $val and $e->[$x] >= $val) or ($n->[$x] >= $val and $e->[$x] <= $val))
	}
	return [$n,$e];
}

sub max
{
	my $self = shift;
	my $formula = shift;
	my $ff = expression_function($formula);
	return undef unless defined $ff;
	my $max = undef;
	foreach my $d (@{$self->{data}})
	{
		my $nm = &$ff([$d]);
		$max = $nm if !defined $max or $nm > $max;
	}
	return $max;
}

# A little Hack for now...
# Return the two indices for the two biggest expression values.
# Idea: Between those, the "real" maximum is to be found, perhaps using non-linear interpolation.
sub max_interval
{
	my $self = shift;
	my $formula = shift;
	my $ff = expression_function($formula);
	return undef unless defined $ff;
	my @maxval;
	my @maxidx;
	for my $idx (1..$#{$self->{data}})
	{
		my $nm = &$ff([$self->{data}[$idx]]);
		if(@maxval)
		{
			if($nm >= $maxval[0])
			{
				$maxval[1] = $maxval[0];
				$maxval[0] = $nm;
				$maxidx[1] = $maxidx[0];
				$maxidx[0] = $idx;
			}
			elsif($nm > $maxval[1])
			{
				$maxval[1] = $nm;
				$maxidx[1] = $idx;
			}
		}
		else
		{
			@maxidx = ($idx, $idx);
			@maxval = ($nm, $nm);
		}
	}
	return @maxidx;
}

sub min
{
	my $self = shift;
	my $formula = shift;
	$formula = '-('.$formula.')';
	return -1*$self->max($formula);
}

sub sort_func
{
	my $self = shift;
	my $cols = shift;
	my $down = shift;
	my $sortcode = 'my $r; ';
	my $i = -1;
	# tested example sortcode:
	# '{ my $c; ($c= $a->[0] <=> $b->[0]) ? $c : ($c= $a->[1] <=> $b->[1]) ? $c : 0 }'
	foreach my $prec (@{$cols})
	{
		# Ensure only integer values enter evalued code.
		# Invalid numbers get parsed to zero, as perl does normally.
		my $c = $prec =~ /^(\d+)/ ? $1 : 0;
		my $r = '$r';
		my $a = '$a';
		my $b = '$b';
		if(defined $down and $down->[++$i])
		{
			$a = '$b';
			$b = '$a';
		}
		$sortcode .= "($r= $a\->[$c] <=> $b\->[$c]) ? $r : ";
	}
	$sortcode .= '0';
	# Not sure... is it better to eval that function here or to to put the eval into the sort call?
	#print STDERR "Sort code: $sortcode\n";
	return eval 'sub {'.$sortcode.'}';
}

sub sort_data
{
	my $self = shift;
	my $cols = shift;
	my $down = shift;
	my $sortfunc = shift;
	unless(defined $sortfunc)
	{
		$sortfunc = $self->sort_func($cols,$down);
	}
	@{$self->{data}} = sort $sortfunc @{$self->{data}};
	return $sortfunc; # Possibility to reuse the sort function.
}

# Heck, this is the gut of txdcalc.
# I do wonder if I could make that use this function here...
# ... or a line-oriented version, rather.
sub calc
{
	my $self      = shift;
	my $formula   = shift; # formula string
	my $config    = shift; # {'byrow'=>0, 'bycol'=>0 }
	my $files     = shift; # list of files to use for [2,1] style refs
	my $workarray = shift; # \@A
	my $constants = shift; # \@C

	my $ff = formula_function($formula);
	return 0 unless defined $ff;

	require Text::NumericData::FileCalc;
	my $deletelist = Text::NumericData::FileCalc::file_calc
	(
	  $ff
	, $config
	, $self->{data}
	, $files
	, $workarray
	, $constants
	);
	return 0 unless defined $deletelist;
	$self->delete_rows($deletelist);

	return 1;
}

# delete indicated rows from data set
sub delete_rows
{
	my $self = shift;
	my $delist = shift;
	return unless defined $delist;
	my @delis = sort {$a <=> $b} @{$delist};
	while(@delis and $delis[0]<0){ shift(@delis); }
	while(@delis and $delis[$#delis]>$#{$self->{data}}){ pop(@delis); }

	return unless @delis;
	# This is designed to handle possibly many sparse deletes in one go.
	# One simple splice() wouldn't do it. Many would be wasteful.
	# This is a rather stupid approach, but at least linear and
	# light on index confusion.
	my @newdata;
	my $row = 0;
	while(@delis)
	{
		my $pi = shift(@delis);
		# splice off the leading part including the to-be-deleted one
		my @part = splice(@{$self->{data}}, 0, $pi-$row+1);
		$row += @part;
		pop(@part);
		push(@newdata, @part);
		# make sure the next index is different
		while(@delis and $delis[0] == $pi){ shift(@delis); }
	}
	push(@newdata, splice(@{$self->{data}}, 0));
	$self->{data} = \@newdata;
}

sub mean
{
	my ($self, $col, $xcol, $begin, $end) = @_;
	my $count = 0;
	my $sum = 0;
	defined $self->{sorted_data}->[$xcol] or $self->compute_sorted_index([$xcol]);
	foreach my $a (@{$self->{sorted_data}->[$xcol]})
	{
		if($a->[$xcol] >= $start)
		{
			if($a->[$xcol] <= $end){ $sum += $a->[$col]; ++$count; }
			else{ last; }
		}
	}
	return $count > 0 ? $sum/$count : undef;
}

sub get_sorted_data
{
	my $self = shift;
	my $x = shift;
	defined $self->{sorted_data}->[$x] or $self->compute_sorted_index([$x]);
	return $self->{sorted_data}->[$x];
}

sub columns
{
	my $self = shift;
	return @{$self->{data}} ? $#{$self->{data}[0]}+1 : 0;
}

1;

__END__

=head1 NAME

Text::NumericData::File - process a whole file with text data

=head1 SYNOPSIS

	use Text::NumericData::File;

	#read $filename on construction
	my $file = new Text::NumericData::File(\%config,$filename);

	#create a fresh object without contents...
	my $file2 = new Text::NumericData::File(\%config);
	#...and read the file afterwards
	$file2->read_all($filename);	

	print "third value of fourth data set: ",$file->{data}->[3][2],"\n";	

=head1 DESCRIPTION

This is a subclass of Text::NumericData::Lines, so all properties are still there and only some sugar is added. It abstracts a file and contains all data for instant access (and memory consumption;-).
There is the possibility to address the data sets indexed via an arbitrary colum and to do some interpolation between points in this index.
A word on this index: It connects one value of the index column with the first data set it occured in - other sets containing this value are not concerned!

=head1 MEMBERS

=head2 Methods

=over 4

=item * init

erases data and parsed config stuff from memory; leaving only in_file and out_file untouched

=item * read_head($file)

Just read head part of file (titles), closing file afterwards or slurping the header including first data line into the buffer.

=item * read_all($file)

Read the data from the filename provided on construction or from $file if defined (where the internal value for the associated filename is set to $file). If $file is the empty string, data is read from STDIN.

This wraps around pipe operation using L<Text::ASCIIPipe>. The return codes are identical to Text::ASCIIPipe::pull_file, i.e. <0 is error, =0 is fine, but no more files to expect, >0 fine, expect more files via pipe.

=item * write_all($file,\@selection)

writes the header and all data or columns in @selection to $file (use WriteFile(undef, \@selection) to write to the internally remembered output file from a previous run).

=item * write_head($handle, \@selection)

writes a header to file handle $handle, tries to provide the appropriate column titles as last line when @selection is defined. Apart from this possibly constructed last line the header here is just the raw header read from the input file - including the original column titles if they were there.

=item * write_data($handle, \@selection)

writes only the data part to file handle

=item * write_new_header($handle,\@selection)

constructs a new header according to the selected columns, preserving the title and comments from the old header but putting it in current comment style and omitting the obsolete column title line, and writes it to $handle.

=item * set_of($value,$indexcolumn) -> \@dataset

returns the data set (line) corresponding to $value in the index of $indexcolumn (0 is default if not specified), employing interpolation if configured (default is linear interpolation)

=item * set_of_noint($value,$indexcolumn) -> \@dataset

does the same as above but prevents any interpolation (so, prepare to get nothing).

=item * y($xvalue,$x,$y) -> $yvalue

returns a specific "Y" value to the "X" value $xvalue with the optional parameters $x and $y telling which columns we mean with X and Y - they default to 0 and 1; so the name of this method actually makes sense with files that contain X-Y data. This includes interpolation just like set_of().

=item * y_noint($xvalue,$x,$y) -> $yvalue

...see set_of_noint; just the same for y()

=item * neighbours($val,$x) -> \($n1,$n2)

searches two neighbouring points in column $x suitable for interpolation for $val.

=item * compute_index(\@columns)

computes indexes (hash) with elements of the named columns as keys and the according data set (row) as value. Only the first found occurrence of the key in the data makes it into the index! This sets $file->{data_index}. 

=item * compute_sorted_index(\@columns)

computes the sorted indices for @columns (and the normal indices before that if necessary)

=item * get_sorted_data($column) -> \@sorted_data

returns ref to array of all data sets that made it into the index for $column in ascending order in respect to $column.

=item * max($formula) -> $maxval

computes the maximum value of the given formula over all data sets

=item * min($formula) -> $minval

computes the minimum value of the given formula over all data sets

=item * max_val($col) NOT IMPLEMENTED

This may be a faster specialization of Max("[$col]")...

=item * sort_data(\@cols, \@down, \&sortfunction)

Sort the data in-place in a stable manner, according to column indices @cols, in order. Optional boolean array @down decides if we sort down or up (default) for each column.
New in Text::NumericData since 1.10.0: Sort returns the generated function used for sorting (the comparison operator); you can hand this one back as third parameter to re-use it (avoids recompilation of that code). Or you can provide a custom comparison function, even.

=item * calc($formula)

Perform given simple calculation over all data sets. Example:

	$txd->calc('[2]*=10');

will multiply the values of the second column by 10.

=item * calc($formula, \@files, \@A, \@C, \%config)

Applies the full power of Text::NumericData::FileCalc. Refer to that module for details.

=item * mean($col, $xcol, $begin, $end) -> $mean_value

calculates the arithmetic mean value of column $col taken according the given range $begin to $end of column $xcol
Hm, this perhaps should also compute RMS.

=item * columns()

Give number of columns in data.

=item * delete_rows(@list)

Delete the rows indicated by the given index list (starting at 0) from the data set. for a single item or block, you can just use splice() yourself. This method is trying to delete multiple sparsely placed rows in an effective manner (many whole-array-splices would be rather wasteful).

=back

=head2 data

Here are some keys for the hash reference representing a Text::NumericData::File.

=over 4

=item * data

2-dimensional array reference. Stores values as $file->{data}->[$row][$col] (data row/record/set and column start at 0, while the indices in formulae start at 1). The transpose of this might make more sense in applcation, though. Future versions could go that route. But this here is what naturally follows the file structure.

=item * records

Count of non-empty records (data lines).

=item * data_index

An alternative access for the data sets; $file->{data_index}->[$indexcol]->{$value} is a reference to the data set where $value stands in column $indexcol (in fact only the first occurence).

=item * sorted_data

@{$file->{sorted_data}->[$x]} contains the data sets that made it into the index of column $x in ascending order concerning the values of column $x.

=item * buffer

A raw string buffer holding file (stdin) containing what has been read by ReadHead and may be inaccessible otherwise.

=back

=head2 Configuration hash keys:

=over 4 

=item * interpolation ('linear')

You can choose which type of interpolation is performed. Either 'linear' for simple built-in linear interpolation or 'spline' for splines provided by Math::Spline.

=item * indexformat

sprintf-style format string for formatting (implies rounding) values for index keys

=item * orderedint (0)

This is effective for the built-in linear interpolation only.
Normally, interpolation is made between the nearest neighbours of the desired value - determined out of the whole file with SortedIndex. If this option is true, however, the data sets are searched in the true order of the file, thus interpolation takes place between the first two points that appear to enclose the wanted one. This may be preferrable in some situations where the data is not monotonic in the variable used as index.

=item * extrapol (1)

The linear interpolation only extrapolates if this is set. The splines always extrapolate.

=back

=head1 AUTHOR

Thomas Orgis <thomas@orgis.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2013, Thomas Orgis.

This module is free software; you
can redistribute it and/or modify it under the same terms
as Perl 5.10.0. For more details, see the full text of the
licenses in the directory LICENSES.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.

