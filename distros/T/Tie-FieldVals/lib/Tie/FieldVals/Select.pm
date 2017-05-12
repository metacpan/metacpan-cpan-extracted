package Tie::FieldVals::Select;
use strict;
use warnings;

=head1 NAME

Tie::FieldVals::Select - an array tie for a subset of Tie::FieldVals data

=head1 VERSION

This describes version B<0.6203> of Tie::FieldVals::Select.

=cut

our $VERSION = '0.6203';

=head1 SYNOPSIS

    use Tie::FieldVals;
    use Tie::FieldVals::Row;
    use Tie::FieldVals::Select;

    my @sel_recs;
    my $sel_obj = tie @sel_recs, 'Tie::FieldVals::Select',
	datafile=>$datafile, selection=>{$key=>$value...};

    # sort the records
    $sel_obj->sort_records(sort_by=>@sort_order);

=head1 DESCRIPTION

This is a Tie object to map a SUBSET of the records in a Tie::FieldVals
data file into an array.  It is a sub-class of Tie::FieldVals.  This is
useful as a separate object because one can do things to it without
affecting the underlying file, unlike with a Tie::FieldVals object.  One
can re-select the data, sort the data, or take a temporary "slice" of the
data.

This depends on the Tie::FieldVals and Tie::FieldVals::Row modules.

=cut

use 5.006;
use strict;
use Carp;
use Tie::FieldVals;
use Tie::FieldVals::Row;
use Fcntl qw(:DEFAULT);
use Data::Dumper;

our @ISA = qw(Tie::FieldVals);

# to make taint happy
$ENV{PATH} = "/bin:/usr/bin:/usr/local/bin";
$ENV{CDPATH} = '';
$ENV{BASH_ENV} = '';

# for debugging
my $DEBUG = 0;

#================================================================
# Methods

=head1 OBJECT METHODS

=head2 make_selection

Select the records (again).  Resets the selection and re-makes it
with the new selection criteria.

    $arr_obj->make_selection(selection=>{$key=>$value},
		    match_any=>$val2);

    $arr_obj->make_selection(selection=>$value);

=cut
sub make_selection {
    my $self = shift;
    my %args = (
	selection=>undef,
	match_any=>undef,
	@_
    );
    my $select = $args{selection};
    my $match_any = $args{match_any};

    # now, apply the selection to the records
    my @records = ();
    my $count = $self->SUPER::FETCHSIZE();
    for (my $i=0; $i < $count; $i++)
    {
	my $add_this_row = 0;
	# if there is no 'selection' then get all the records
	if ((!defined $select || !$select)
	    && (!defined $match_any || !$match_any))
	{
	    $add_this_row = 1;
	}
	elsif (!ref $select) # match any
	{
	    my $row_ref = $self->SUPER::FETCH($i);
	    my $row_obj = tied %{$row_ref};
	    if ($row_obj->match_any($select))
	    {
		$add_this_row = 1;
	    }
	}
	elsif (defined $match_any && $match_any)
	{
	    my $row_ref = $self->SUPER::FETCH($i);
	    my $row_obj = tied %{$row_ref};
	    if ($row_obj->match_any($match_any))
	    {
		$add_this_row = 1;
	    }
	}
	elsif (ref $select eq 'ARRAY') # select a range
	{
	    my $first = ${$select}[0];
	    my $last = ${$select}[1];
	    if ($i >= $first && $i <= $last)
	    {
		$add_this_row = 1;
	    }
	}
	elsif (ref $select eq 'HASH')
	{
	    my $row_ref = $self->SUPER::FETCH($i);
	    my $row_obj = tied %{$row_ref};
	    if ($row_obj->match(%{$select}))
	    {
		$add_this_row = 1;
	    }
	}
	# add the index for this row to our records
	if ($add_this_row)
	{
	    push @records, $i;
	}
    }
    $self->{SEL_RECS} = \@records;
    # set the full slice
    $self->{OPTIONS}->{start_rec} = 0;
    $self->{OPTIONS}->{num_recs} = scalar @{$self->{SEL_RECS}};

} # make_selection

=head2 set_sel_slice

Set this selection to a sub-set of itself.  In other words,
keep the original selection, but perform all operations
on a slice of it.  Assumes the array is sorted, and that
the selection is related to the sort order (for example,
that I<key1>=>I<value1> where I<key1> is the first key of the sort
order).

    $arr_obj->set_sel_slice(selection=>{$key=>$value},
		    match_any=>$val2,
		    start_at_zero=>0);

=cut
sub set_sel_slice {
    my $self = shift;
    my %args = (
	selection=>undef,
	match_any=>undef,
	start_at_zero=>0,
	@_
    );

    my $select = $args{selection};
    my $match_any = $args{match_any};
    if ($DEBUG)
    {
	print STDERR "set_sel_slice:";
	print STDERR " selection=";
	print STDERR Dumper($select);
    }

    # now, apply the sub-selection to the current selection
    my @records = ();
    my $count = @{$self->{SEL_RECS}};
    my $start_range = 0;
    my $start_offset;
    if ($args{start_at_zero})
    {
	$self->{OPTIONS}->{start_rec} = 0;
	$start_offset = 0;
    }
    else
    {
	# start from the next record after the current slice
	# but only if we have been slicing
	if ($self->{OPTIONS}->{num_recs} < $count)
	{
	    $self->{OPTIONS}->{start_rec} += 
		$self->{OPTIONS}->{num_recs};
	}
	$start_offset = $self->{OPTIONS}->{start_rec};
	# set the count to be from the offset start
	# to the end of the SEL_RECS array
	$count = ($count - $self->{OPTIONS}->{start_rec});
    }
    # reset the curent slice to be as big as possible
    $self->{OPTIONS}->{num_recs} = $count;

    my $end_range = 0;
    my $matches = 0;
    my $this_row_matches = 0;
    my $match_found = 0;
    if ($DEBUG)
    {
	print STDERR "set_sel_slice: checking $count records\n";
    }
    for (my $i=0; $i < $count; $i++)
    {
	$this_row_matches = 0;
	# if there is no 'selection' then get all the records
	if (!defined $select && !defined $match_any)
	{
	    $this_row_matches = 1;
	}
	elsif (!ref $select) # match any
	{
	    my $row_ref = $self->FETCH($i);
	    my $row_obj = tied %{$row_ref};
	    if ($row_obj->match_any($select))
	    {
		$this_row_matches = 1;
	    }
	}
	elsif (ref $select eq 'ARRAY')
	{
	    my $first = ${$select}[0];
	    my $last = ${$select}[1];
	    if ($i >= $first && $i <= $last)
	    {
		$this_row_matches = 1;
	    }
	}
	elsif (ref $select eq 'HASH')
	{
	    my $row_ref = $self->FETCH($i);
	    my $row_obj = tied %{$row_ref};
	    if ($row_obj->match(%{$select}))
	    {
		$this_row_matches = 1;
		if ($DEBUG)
		{
		    print STDERR "row=[$i]";
		    print STDERR Dumper($row_ref);
		}
	    }
	}
	elsif (defined $match_any && $match_any)
	{
	    my $row_ref = $self->FETCH($i);
	    my $row_obj = tied %{$row_ref};
	    if ($row_obj->match_any($match_any))
	    {
		$this_row_matches = 1;
	    }
	}
	# have we started matching?
	if (!$matches)
	{
	    if ($this_row_matches)
	    {
		$start_range = $i;
		$match_found = 1;
		$matches = 1;
	    }
	}
	# the end-range is always increasing so long
	# as the row matches
	if ($this_row_matches)
	{
	    $end_range = $i;
	}
	# have we stopped matching?  If so, stop looking.
	if ($matches)
	{
	    if (!$this_row_matches)
	    {
		$matches = 0;
		last;
	    }
	}
    }
    $self->{OPTIONS}->{start_rec} = $start_offset + $start_range;
    $self->{OPTIONS}->{num_recs} = ($end_range - $start_range) + 1;
    if (!$match_found)
    {
	$self->{OPTIONS}->{num_recs} = 0;
    }
    if ($DEBUG)
    {
	print STDERR "set_sel_slice:";
	print STDERR " start_rec=", $self->{OPTIONS}->{start_rec};
	print STDERR " end_range=", $end_range;
	print STDERR " num_recs=", $self->{OPTIONS}->{num_recs};
	print STDERR "\n";
    }
} # set_sel_slice

=head2 clear_sel_slice

Restore this selection to the full selection (if it has been
previously "sliced").  If it hasn't been previously sliced, then
calling this makes no difference.

$arr_obj->clear_sel_slice();

=cut
sub clear_sel_slice {
    my $self = shift;
    my %args = (
	@_
    );

    $self->{OPTIONS}->{start_rec} = 0;
    $self->{OPTIONS}->{num_recs} = scalar @{$self->{SEL_RECS}};
} # clear_sel_slice

=head2 sort_records

$sel->sort_records(
    sort_by=>[qw(Author Series SeriesOrder Title Date)],
    sort_numeric=>{ SeriesOrder=>1 },
    sort_title=>{ Title=>1 },
    sort_lastword=>{ Author=>1 },
    sort_reversed=>{ Date=>1 });

Take the current selected records array and sort it by field names.
The B<sort_by> array contains an array of field names for this data.
Yes, that's right, you can sort on multiple fields.

The other arguments are for indications of changes to the type of sorting
done on the given fields.

=over

=item sort_numeric

The given field(s) should be sorted as numbers.
Note that for multi-valued fields, this compares only the first value
in the set.

=item sort_title

The given field(s) should be treated as titles: any leading "The "
or "A " will be ignored.

=item sort_lastword

The given field(s) will be sorted with their last word first
(such as for surnames).

=item sort_reversed

The given field(s) will be sorted in reverse order.

=back

=cut
sub sort_records ($%) {
    my $self = shift;
    my %args = (
	sort_by => undef,
	sort_numeric => undef,
	sort_reversed => undef,
	sort_title => undef,
	sort_lastword => undef,
	@_
    );
    my $records_ref = $self->{SEL_RECS};

    my @sort_fields = @{$args{sort_by}};
    my @sort_order = ();
    my %sort_numerically = (defined $args{sort_numeric}
	? %{$args{sort_numeric}} : ());
    my %sort_reversed = (defined $args{sort_reversed}
	? %{$args{sort_reversed}} : ());
    my %sort_title = (defined $args{sort_title} ? %{$args{sort_title}} : ());
    my %sort_lastword = (defined $args{sort_lastword}
	? %{$args{sort_lastword}} : ());
    # filter out any illegal fields
    foreach my $sfname (@sort_fields)
    {
	if (exists $self->{field_names_hash}->{$sfname}
	    && defined $self->{field_names_hash}->{$sfname}
	    && $self->{field_names_hash}->{$sfname})
	{
	    push @sort_order, $sfname;
	}
    }

    # pre-cache the actual comparison values
    my %values = ();
    foreach my $rec (@{$records_ref})
    {
	my $a_row = $self->SUPER::FETCH($rec);
	$values{$rec} = {};
	foreach my $fn (@sort_order)
	{
	    # allow for multi-valued fields
	    my @a_arr = @{$a_row->{\$fn}};
	    if (!@a_arr)
	    {
		if (defined $sort_numerically{$fn}
		    && $sort_numerically{$fn})
		{
		    # sort undefined as zero
		    $values{$rec}->{$fn} = 0;
		}
		else
		{
		    # sort undefined as the empty string
		    $values{$rec}->{$fn} = '';
		}
	    }
	    else
	    {
		my $a_val = '';
		if (defined $sort_numerically{$fn}
		    && $sort_numerically{$fn})
		{
		    # multi-valued fields don't make sense for
		    # numeric comparisons, so just take the first one
		    $a_val = $a_arr[0];
		    $a_val =~ s/\s//g; # remove any spaces
		    # non-numeric data should be compared as zero
		    if (!defined $a_val
			|| !$a_val
			|| $a_val =~ /\D/)
		    {
			$a_val = 0;
		    }
		}
		else # strings
		{
		    # allow for titles
		    if ($sort_title{$fn})
		    {
			@a_arr = map { s/^(The\s+|A\s+)//; $_ } @a_arr;
		    }
		    # do lastword stuff
		    if ($sort_lastword{$fn})
		    {
			@a_arr = map { s/^(.*)\s+(\w+)$/$2,$1/; $_ } @a_arr;
		    }
		    $a_val = join('###', @a_arr);
		}
		$values{$rec}->{$fn} = $a_val;
	    }
	}
    }

    my @sorted_records = sort {
	my $result = 0;
	foreach my $fn (@sort_order)
	{
	    my $a_val = $values{$a}->{$fn};
	    my $b_val = $values{$b}->{$fn};
	    $result =
	    (
	     (defined $sort_reversed{$fn} && $sort_reversed{$fn})
	     ? (
		(defined $sort_numerically{$fn} && $sort_numerically{$fn})
		?  ($b_val <=> $a_val)
		: ($b_val cmp $a_val)
	       )
		: (
		   (defined $sort_numerically{$fn} && $sort_numerically{$fn})
		   ?  ($a_val <=> $b_val)
		   : ($a_val cmp $b_val)
		  )
	    );
	    if ($result != 0)
	    {
		return $result;
	    }
	}
	$result;
    } @{$records_ref};

    @{$self->{SEL_RECS}} = @sorted_records;

} # sort_records

=head2 get_column

Get the data from a column.

    my @col = $obj->get_column(field_name=>$field_name,
				unique=>1);

If unique is true, then duplicate values will be eliminated.

This can be useful in operating on subsets of the selection, for example if
one has sorted on a field, then one gets the column data for that field,
with "unique" to true, then calls L</set_sel_slice> with each unique
value...

=cut
sub get_column ($%) {
    my $self = shift;
    my %args = (
	field_name =>'',
	unique =>1,
	@_
    );

    my @col = ();
    my %col_vals = ();
    for (my $i=0; $i < @{$self->{SEL_RECS}}; $i++)
    {
	my $vals_ref = $self->FETCH($i);
	my $val = $vals_ref->{$args{field_name}};
	if ($args{unique})
	{
	    if (!$col_vals{$val})
	    {
		push @col, $val;
	    }
	}
	else
	{
	    push @col, $val;
	}
	$col_vals{$val} = 1;
    }
    return @col;
} # get_column

#================================================================
# Tie-Array interface

=head1 TIE-ARRAY METHODS

=head2 TIEARRAY

Create a new instance of the object as tied to an array.

    tie @SEL_RECS, 'Tie::FieldVals::Select',
	datafile=>$datafile, selection=>{$key=>$value},
	match_any=>$val_any;

The selection and match_any options are the selection criteria
used to define this sub-set; they have the same format as
those used in L<Tie::FieldVals::Row/match> and
L<Tie::FieldVals::Row/match_any> methods.

Other options are the same as for L<Tie::FieldVals/TIEARRAY>.

=cut
sub TIEARRAY {
    my $class = shift;

    # make the parent tie
    my $self = Tie::FieldVals::TIEARRAY($class, @_);
    # now, FILE_OBJ, FILE_RECS, OPTIONS, REC_CACHE, field_names
    # field_names_hash
    # should be set
    
    # set the default additional options
    $self->{OPTIONS}->{selection} ||= undef;
    $self->{OPTIONS}->{match_any} ||= undef;

    # now, apply the selection to the records
    $self->make_selection(%{$self->{OPTIONS}});

    return $self;
} # TIEARRAY

=head2 FETCH

Get a row from the array.

    $val = $array[$ind];

Returns a reference to a Tie::FieldVals::Row hash, or undef.

=cut
sub FETCH {
    carp &whowasi if $DEBUG;
    my ($self, $ind) = @_;

    if ($ind >= 0 && $ind < $self->{OPTIONS}->{num_recs})
    {
	my $s_ind = $ind + $self->{OPTIONS}->{start_rec};
	my $real_ind = ${$self->{SEL_RECS}}[$s_ind];
	if ($DEBUG)
	{
	    print STDERR "ind=$ind";
	    print STDERR " s_ind=$s_ind";
	    print STDERR " real_ind=$real_ind";
	    print STDERR "\n";
	    print STDERR Dumper(${$self->{FILE_RECS}}[$real_ind]);
	}
	return $self->SUPER::FETCH($real_ind);
    }
    return undef;
} # FETCH

=head2 STORE

Set a value in the array.

    $array[$ind] = $val;

If $ind is bigger than the array, then do nothing.  (If you want to add a
new row to the data file, do it directly with the Tie::FieldVals array.)
The $val is expected to be a Tie::FieldVals::Row hash.
This I<does> replace the given the data in the data file.

=cut
sub STORE {
    carp &whowasi if $DEBUG;
    my ($self, $ind, $val) = @_;

    if ($ind >= 0 && $ind < $self->{OPTIONS}->{num_recs})
    {
	my $s_ind = $ind + $self->{OPTIONS}->{start_rec};
	my $real_ind = ${$self->{SEL_RECS}}[$s_ind];
	$self->SUPER::STORE($real_ind, $val);
    }
} # STORE

=head2 FETCHSIZE

Get the apparent size of the array.  This gives the
size of the current slice, not the size of the underlying
array.  Of course if we are not in "slice" mode, the two values
will be the same.

=cut
sub FETCHSIZE {
    carp &whowasi if $DEBUG;
    my $self = shift;

    return $self->{OPTIONS}->{num_recs};
} # FETCHSIZE

=head2 STORESIZE

Set the apparent size of the array.
This actually sets the size of the current slice of the array,
not the underlying array.

=cut
sub STORESIZE {
    carp &whowasi if $DEBUG;
    my $self = shift;
    my $count = shift;

    if ($count <= @{$self->{SEL_RECS}})
    {
	$self->{OPTIONS}->{num_recs} = $count;
    }
} # STORESIZE

=head2 EXISTS

    exists $array[$ind];

Note that if the array is in "slice" mode, this will only
say whether the row exists in the slice.

=cut
sub EXISTS {
    carp &whowasi if $DEBUG;
    my $self = shift;
    my $ind = shift;

    if ($ind >= 0 && $ind < $self->{OPTIONS}->{num_recs})
    {
	my $s_ind = $ind + $self->{OPTIONS}->{start_rec};
	my $real_ind = ${$self->{SEL_RECS}}[$s_ind];
	return $self->SUPER::EXISTS($real_ind);
    }
    return 0;
} # EXISTS

=head2 DELETE

    delete $array[$ind];

Delete the value at $ind -- deletes from the selection.
Does not delete from the data file.

=cut
sub DELETE {
    carp &whowasi if $DEBUG;
    my $self = shift;
    my $ind = shift;

    if ($ind >= 0 && $ind < $self->{OPTIONS}->{num_recs})
    {
	my $s_ind = $ind + $self->{OPTIONS}->{start_rec};
	delete ${$self->{SEL_RECS}}[$s_ind];
	$self->{OPTIONS}->{num_recs}--;
    }
} # DELETE

=head2 CLEAR

    @array = ();

Clear the array -- clears the selection.
Does not affect the data file.

=cut
sub CLEAR {
    carp &whowasi if $DEBUG;
    my $self = shift;
    my $ind = shift;

    @{$self->{SEL_RECS}} = ();
    $self->{OPTIONS}->{start_rec} = 0;
    $self->{OPTIONS}->{num_recs} = 0;
} # CLEAR

=head2 UNTIE

    untie @array;

Untie the array.

=cut
sub UNTIE {
    carp &whowasi if $DEBUG;
    my $self = shift;
    my $count = shift;

    carp "untie attempted while $count inner references still exist" if $count;
    $self->{SEL_RECS} = [];
    $self->{OPTIONS}->{start_rec} = 0;
    $self->{OPTIONS}->{num_recs} = 0;
    $self->SUPER::UNTIE($count);
} # UNTIE

=head1 PRIVATE METHODS

For developer reference only.

=head2 debug

Set debugging on.

=cut
sub debug { $DEBUG = @_ ? shift : 1 }

=head2 whowasi

For debugging: say who called this 

=cut
sub whowasi { (caller(1))[3] . '()' }

=head1 REQUIRES

    Test::More
    Carp
    Data::Dumper
    Fcntl
    Tie::FieldVals
    Tie::FieldVals::Row

=head1 SEE ALSO

perl(1).
L<Tie::FieldVals>
L<Tie::FieldVals::Row>

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot com
    http://www.katspace.com

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2004 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Tie::FieldVals::Select
# vim: ts=8 sts=4 sw=4
__END__
