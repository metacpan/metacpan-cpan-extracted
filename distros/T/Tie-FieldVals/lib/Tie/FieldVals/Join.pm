package Tie::FieldVals::Join;
use strict;
use warnings;

=head1 NAME

Tie::FieldVals::Join - an array tie for two files of FieldVals data

=head1 VERSION

This describes version B<0.6203> of Tie::FieldVals::Join.

=cut

our $VERSION = '0.6203';

=head1 SYNOPSIS

    use Tie::FieldVals;
    use Tie::FieldVals::Row;
    use Tie::FieldVals::Join;
    use Tie::FieldVals::Row::Join;

    my @records;

    my $recs_obj = tie @records, 'Tie::FieldVals::Join',
	datafile=>$datafile, joinfile=>$joinfile,
	join_field=>$fieldname, selection=>{$key=>$value};

=head1 DESCRIPTION

This is a Tie object to map the records in two FieldVals data files
into an array.

This depends on the Tie::FieldVals::Row::Join module.

=cut

use 5.006;
use strict;
use Carp;
use Tie::Array;
use Tie::FieldVals;
use Tie::FieldVals::Row;
use Tie::FieldVals::Row::Join;
use Fcntl qw(:DEFAULT);
use Data::Dumper;

our @ISA = qw(Tie::Array);

# to make taint happy
$ENV{PATH} = "/bin:/usr/bin:/usr/local/bin";
$ENV{CDPATH} = '';
$ENV{BASH_ENV} = '';

# for debugging
my $DEBUG = 0;

#================================================================
# Methods

=head1 OBJECT METHODS

=head2 field_names

Get the field names of this data.

my @field_names = $recs_obj->field_names();

=cut
sub field_names {
    carp &whowasi if $DEBUG;
    my $self = shift;

    @{$self->{all_field_names}};
}

#================================================================
# Object interface

=head1 Tie-Array METHODS

=head2 TIEARRAY

Create a new instance of the object as tied to an array.
This is a read-only array.

    tie %person, 'Tie::FieldVals::Join', datafile=>$datafile,
	joinfile=>$joinfile, join_field=>$fieldname,
	selection=>{$key=>$value...}, match_any=>$val2;

    tie %person, 'Tie::FieldVals::Join', datafile=>$datafile,
	joinfile=>$joinfile, join_field=>$fieldname,
	cache_size=>1000, memory=>0;

    tie %person, 'Tie::FieldVals::Join', datafile=>$datafile,
	joinfile=>$joinfile, join_field=>$fieldname,
	selection=>{$key=>$value...}, match_any=>$val2,
	cache_all=>1;

The datafile option is the first file, the joinfile is the second.
The join_field is the field which the two files have in common,
upon which they are joining.  Only rows where both files have
the same value for the join_field will be put in this join.

Note that is a very naieve join algorithm: it expects the B<datafile>
file to have unique values for the B<join_field>, and the B<joinfile>
file to have multiple values for the B<join_field> -- if the order is
the other way around, the results will be messed up.

The join array is read-only.

See L<Tie::FieldVals> and L<Tie::FieldVals::Selection> for explanations of
the other arguments.

=cut
sub TIEARRAY {
    carp &whowasi if $DEBUG;
    my $class = shift;
    my %args = (
	datafile=>'',
	joinfile=>'',
	join_field=>'',
	cache_size=>100,
	cache_all=>0,
	memory=>10_000_000,
	selection=>undef,
	match_any=>undef,
	@_
    );

    my $self = {};
    $self->{OPTIONS} = \%args;

    # find the field names
    $self->{FIELD_NAMES} = [];
    @{$self->{FIELD_NAMES}->[0]} =
	Tie::FieldVals::find_field_names($args{datafile});
    @{$self->{FIELD_NAMES}->[1]} =
	Tie::FieldVals::find_field_names($args{joinfile});

    # set the combined field names
    my @field_names = @{$self->{FIELD_NAMES}->[0]};
    my %field_names_hash1 = ();
    foreach my $fn (@{$self->{FIELD_NAMES}->[0]})
    {
	$field_names_hash1{$fn} = 1;
    }

    my %field_names_hash2 = ();
    foreach my $fn (@{$self->{FIELD_NAMES}->[1]})
    {
	if ($fn ne $args{join_field})
	{
	    push @field_names, $fn;
	}
	$field_names_hash2{$fn} = 1;
    }
    $self->{all_field_names} = \@field_names;

    # split the selection, if any, into a selection for the first
    # file and the selection for the second file.
    my %sel1 = ();
    my %sel2 = ();
    if (defined $args{selection})
    {
	foreach my $key (keys %{$args{selection}})
	{
	    if ($field_names_hash1{$key}) # in first file
	    {
		$sel1{$key} = $args{selection}->{$key};
	    }
	    if ($field_names_hash2{$key}) # in second file
	    {
		$sel2{$key} = $args{selection}->{$key};
	    }
	}
    }

    # make a selection from the files, so they can
    # be sorted on the join_field
    $self->{SEL_RECS} = [];
    $self->{SEL_OBJS} = [];
    my @sel_recs1;
    $self->{SEL_OBJS}->[0] = tie @sel_recs1, 'Tie::FieldVals::Select',
	datafile=>$args{datafile},
	selection=>(%sel1 ? \%sel1 : undef),
	match_any=>$args{match_any}
	or die "Tie::FieldVals::Join - Could not select", $args{datafile}, ".";
    $self->{SEL_RECS}->[0] = \@sel_recs1;
    my @sel_recs2;
    $self->{SEL_OBJS}->[1] = tie @sel_recs2, 'Tie::FieldVals::Select',
	datafile=>$args{joinfile},
	selection=>(%sel2 ? \%sel2 : undef),
	match_any=>$args{match_any}
	or die "Tie::FieldVals::Join - Could not select", $args{joinfile}, ".";
    $self->{SEL_RECS}->[1] = \@sel_recs2;

    # sort on the join field
    for (my $i = 0; $i < 2; $i++)
    {
	$self->{SEL_OBJS}->[$i]->sort_records(
	    sort_by=>[$args{join_field}]);
    }
    
    # join the two files on the join field
    my @join_recs = ();
    my $i = 0;
    my $j = 0;
    foreach my $row1_ref (@sel_recs1)
    {
	my $row1_obj = tied %{$row1_ref};

	my $join_val = $row1_ref->{$args{join_field}};
	if ($join_val)
	{
	    $join_val = "eq $join_val"; # make an exact compare
	}
	else
	{
	    $join_val = "eq ''";
	}
	my $row2_ref = undef;
	my $row2_obj = undef;
	if ($j < @sel_recs2)
	{
	    $row2_ref = $sel_recs2[$j];
	    $row2_obj = tied %{$row2_ref};
	}
	# since these are sorted, just keep going until no match
	while ($j < @sel_recs2
	    && $row2_obj->match($args{join_field}=>$join_val))
	{
	    # we have a value for both tables!
	    push @join_recs, [$i, $j];
	    $j++;
	    $row2_ref = $sel_recs2[$j];
	    $row2_obj = tied %{$row2_ref};
	}
	$i++;
    }
    $self->{JOIN_RECS} = \@join_recs;
    $self->{REC_CACHE} = {};
    if ($args{cache_all}) # set the cache to the size of the file
    {
	my $count = @join_recs;
	$self->{OPTIONS}->{cache_size} = $count;
    }

    bless $self, $class;
} # TIEARRAY

=head2 FETCH

Get a row from the array.

    $val = $array[$ind];

Returns a reference to a Tie::FieldVals::Row::Join hash, or undef.

=cut
sub FETCH {
    carp &whowasi if $DEBUG;
    my ($self, $ind) = @_;

    if (defined $self->{REC_CACHE}->{$ind})
    {
	return $self->{REC_CACHE}->{$ind};
    }
    else # not cached, add to cache
    {
	# remove one from cache if cache full
	my @cached = keys %{$self->{REC_CACHE}};
	if (@cached >= $self->{OPTIONS}->{cache_size})
	{
	    delete $self->{REC_CACHE}->{shift @cached};
	}
	# get the records from the files
	my $file_ind_ar_ref = $self->{JOIN_RECS}->[$ind];
	my @rec_strs = ();
	my @rows = ();

	my $find = ${$file_ind_ar_ref}[0];
	my $srow_ref = $self->{SEL_RECS}->[0]->[$find];
	my $srow_obj = tied %{$srow_ref};

	%{$self->{REC_CACHE}->{$ind}} = ();
	my $row_obj = tie %{$self->{REC_CACHE}->{$ind}},
	    'Tie::FieldVals::Row::Join', 
	    row=>$srow_obj;

	for (my $fnum=1; $fnum < @{$file_ind_ar_ref}; $fnum++)
	{
	    $find = ${$file_ind_ar_ref}[$fnum];
	    $srow_ref = $self->{SEL_RECS}->[$fnum]->[$find];
	    $srow_obj = tied %{$srow_ref};
	    $row_obj->merge_rows($srow_obj);
	}
	return $self->{REC_CACHE}->{$ind};
    }
    return undef;
} # FETCH

=head2 STORE

Add a value to the array.  Does nothing -- this is read-only.

=cut
sub STORE {
    carp &whowasi if $DEBUG;
    my ($self, $ind, $val) = @_;

    return undef;
} # STORE

=head2 FETCHSIZE

Get the size of the array.

=cut
sub FETCHSIZE {
    carp &whowasi if $DEBUG;
    my $self = shift;

    return scalar @{$self->{JOIN_RECS}};
} # FETCHSIZE

=head2 STORESIZE

Does nothing.

=cut
sub STORESIZE {
    carp &whowasi if $DEBUG;
    my $self = shift;
    my $count = shift;

} # STORESIZE

=head2 EXISTS

    exists $array[$ind];

=cut
sub EXISTS {
    carp &whowasi if $DEBUG;
    my $self = shift;
    my $ind = shift;

    if ($ind >= 0 && $ind < @{$self->{JOIN_RECS}})
    {
	return exists ${$self->{JOIN_RECS}}[$ind];
    }
    return 0;
} # EXISTS

=head2 DELETE

    delete $array[$ind];

Does nothing -- this array is read-only.

=cut
sub DELETE {
    carp &whowasi if $DEBUG;
    my $self = shift;
    my $ind = shift;

    return undef;
} # DELETE

=head2 CLEAR

    @array = ();

Does nothing -- this array is read-only.

=cut
sub CLEAR {
    carp &whowasi if $DEBUG;
    my $self = shift;

} # CLEAR

=head2 UNTIE

    untie @array;

Untie the array.

=cut
sub UNTIE {
    carp &whowasi if $DEBUG;
    my $self = shift;

    $self->{REC_CACHE} = {};
    $self->{JOIN_RECS} = [];
    for (my $i = 0; $i < @{$self->{SEL_RECS}}; $i++)
    {
	undef $self->{SEL_OBJS}->[$i];
	untie @{$self->{SEL_RECS}->[$i]};
    }
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
    Tie::Array
    Fcntl
    Tie::FieldVals
    Tie::FieldVals::Row
    Tie::FieldVals::Row::Join
    Tie::FieldVals::Select

=head1 SEE ALSO

perl(1).
L<Tie::FieldVals>
L<Tie::FieldVals::Row>
L<Tie::FieldVals::Select>
L<Tie::FieldVals::Row::Join>

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

1; # End of Tie::FieldVals::Join
# vim: ts=8 sts=4 sw=4
__END__
