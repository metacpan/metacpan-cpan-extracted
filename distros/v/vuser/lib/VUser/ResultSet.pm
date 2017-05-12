package VUser::ResultSet;
use warnings;
use strict;

# Copyright 2005 Randy Smith

use Carp;
use VUser::Meta;

our $VERSION = "0.5.0";

sub new
{
    my $class = shift;

    my $self = { meta => [],
		 values => [],
		 colmap => {},
		 current => -1,
		 rows => 0,
		 order_by => undef,
		 sort_order => 'asc',
		 lock_meta => 0,
		 error_code => undef,
		 errors => []
		 };

    bless $self, $class;
    return $self;
}

sub get_metadata
{
    my $self = shift;
    return @{$self->{meta}};
}

sub results
{
    my $self = shift;
    my %options = @_;

    return $self->sort_results(%options);
}

sub results_hashrefs
{
    my $self = shift;
    my %options = @_;

    my @results = $self->sort_results(%options);
    return map {
	my $hash = {};
	for (my $i = 0; $i < @{ $self->{meta} }; $i++) {
	    $hash->{$self->{meta}[$i]->name} = $_->[$i];
	}
	$hash;
    } @results;
}

sub sort_results
{
    my $self = shift;
    my %options = @_;

    my $order_by = $options{order_by} || $self->{order_by};
    my $sort_order = $options{sort_order} || $self->{sort_order};

    $order_by = $self->{meta}[0]->name unless defined $order_by;

    $order_by = undef if not defined $self->{colmap}{$order_by};
    $sort_order = 'asc' if ($sort_order ne 'asc' or $sort_order ne 'des');

    my $column_idx = 0;
    $column_idx = $self->{colmap}{$order_by} if defined $order_by;

    # Don't sort if there's no order requested.
    return @{$self->{values}} if (not defined $order_by);

#     print STDERR ("Order: $order_by Idx: $column_idx; Type: ",
# 		  $self->{meta}[$column_idx]->type,
# 		  "\n");

    return sort {
	my ($A, $B) = ($a, $b);
	if ($sort_order eq 'des') {
	    ($A, $B) = ($b, $a);
	}
	
	my $type = $self->{meta}[$column_idx]->type;
	my $res = undef;
	if ($type eq 'string') {
	    $res = $A->[$column_idx] cmp $B->[$column_idx];
	} else {
	    $res = $A->[$column_idx] <=> $B->[$column_idx];
	}
	#print STDERR $A->[$column_idx],' <=> ',$B->[$column_idx]," => $res\n";
	return $res;
    } @{$self->{values}};
}

sub order_by
{
    my $self = shift;
    my $order_by = shift;
    my $sort_order = shift;

    return 0 unless defined $self->{colmap}{$order_by};

    if (not defined $sort_order
	or $sort_order ne 'asc'
	or $sort_order ne 'des') {
	$sort_order = 'asc';
    }

    $self->{order_by} = $order_by;
    $self->{sort_order} = $sort_order;
    return 1;
}

sub add_meta
{
    my $self = shift;
    my $meta = shift;

    die "No more meta data may be added after data has been added." if ($self->{lock_meta} == 1);

    die "Option is not a VUser::Meta object\n" unless UNIVERSAL::isa($meta, "VUser::Meta");

    my $new_idx = @{$self->{meta}};
    $self->{colmap}{$meta->name} = $new_idx;
    push @{$self->{meta}}, $meta;

    return 1;
}

sub add_data
{
    my $self = shift;
    my $data = shift;

    $self->{lock_meta} = 1;

    if (ref $data eq 'ARRAY') {
	if (@{$data} != @{$self->{meta}}) {
	    die "Number of data elements does not match the number of meta entries.";
	}

	push @{$self->{values}}, $data;
	$self->{rows}++;

    } elsif (ref $data eq 'HASH') {
	if (keys %$data != @{$self->{meta}}) {
	    die "Number of data elements does not match the number of meta entries.";
	}

	my $new_data = [];
	foreach my $meta (@{$self->{meta}}) {
	    push @$new_data, $data->{$meta->name};
	}

	push @{$self->{values}}, $new_data;
	$self->{rows}++;
    } else {
	die 'Data is not an array or hash.';
    }

    return 1;
}

sub version { return $VERSION; }

sub error_code {
    my $self = shift;
    if (defined $_[0]) {
	if ($_[0] =~ /^-?\d+$/) {
	    $self->{error_code} = $_[0];
	} else {
	    carp "Error code is not an integer.\n";
	}
    }

    return $self->{error_code};
}

sub errors {
    my $self = shift;

    if (wantarray) {
	return @{ $self->{errors} };
    } else {
	return scalar @{ $self->{errors} };
    }
}

sub add_error {
    my $self = shift;
    my $err = shift;
    my @sprintf_args = @_;

    if (defined $err) {
	push (@{ $self->{errors} },
	      sprintf ($err, @sprintf_args)
	    );
    }
}

sub error {
    my $self = shift;

    if (defined $self->{error_code}) {
	return {'error_code' => $self->error_code(),
		'errors' => $self->errors()};
    } else {
	return undef;
    }
}

sub get_all_errors {
    my @result_sets = @_;

    my @errors = ();

    # And empty @result_sets skips this preventing
    # the recursion below from becoming infinite.
    foreach my $set (@result_sets) {
	if (eval { $set->isa('VUser::ResultSet') }) {
	    if (defined $set->error_code) {
		push (@errors, $set->error);
	    }
	} elsif (eval {ref $set eq 'ARRAY' } ) {
	    # Watch the recursion ...
	    foreach my $rs (get_all_errors(@{ $set })) {
		push @errors, $rs;
	    }
	}
    }

    return @errors;
}

1;

__END__

=head1 NAME

VUser::ResultSet - Data returned by Extension tasks.

=head1 DESCRIPTION

VUser::ResultSets are used to return data from vuser extensions. An
extension can also use it return errors.

=head1 SYSNOPSIS


 my $rs = VUser::ResultSet->new();
 
 $rs->add_meta(VUser::Meta->new(name => "color", type => "string"));
 $rs->add_meta(VUser::Meta->new(name => "size", type => "integer"));
 
 $rs->add_data(["blue", 10]);
 $rs->add_data(["orange", 6]);
 
 # Returning errors
 $rs->error_code(42);
 $rs->add_error("Unknown question: %s",
    'Life, the universe and everything.');
 
 return $rs;

=head1 METHODS

=head2 Creating the ResultSet

The following methods are used by extensions to create a result set that
may be returned from task functions.

=over 4

=item new

Create a new ResultSet object.

=item add_meta(VUser::Meta)

Meta data about the data the task is returning is required so the client
can deal with it in a nice way.

=item add_data([]|{})

add_data() takes either an array reference or hash ref. If it's an array ref,
the array must have the same number of entries as the number of meta data
entries added with add_meta(). Values but also be in the same order or there
will be much confusion.

If a hash reference is passed, the keys must corespond to the names of the
meta data added with add_meta(). (Other keys will be ignored.) The number
if values must match the number of meta data entries created with add_meta.

Once add_data() has been called, no more meta data may be added to the
ResultSet object.

=back

=head2 Returning Errors

You can use a ResultSet to return errors from your extension.

=over 4

=item error_code($)

Sets the error code for the result to the passed in integer value.
If the value passed to C<error_code()> is not an integer, error_code()
will complain and leave the error code unset.

=item add_error($;@)

Adds an error string to the list of errors. The parameters are passed to
sprintf for formatting. See L<perlfunc/sprintf> for more details.

=item errors()

Returns the list of errors set by C<add_error()>.

=back

=head2 Using a ResultSet

These methods are used by apps that call ExtHandler->run_tasks to get the
data out of the returned ResultSet(s).

=over 4

=item results(%)

Get the results. The parameter is a hash with the following keys.

=over 8

=item order_by

The name of the meta data to sort on, if desired. If it's not defined, the
results will be returned in the order the extension added them.

=item sort_order

Value may be one of 'asc' or 'des'. 'asc' means sort in ascending order,
'des' is descending order. Ascending is the default. This has no effect if
I<order_by> is not specified or is an unknown column.

=back

=item get_metadata

Get the list of meta data for this result set. Each value is a VUser::Meta
object.

=back

=head1 development notes

The following are notes that I wrote while developing this system. They
should match reality but aren't guaranteed to.

task() return values.

Return the following info:

extension name (needed?)
result set
	meta
	value(s)

result set:
{
 meta = [meta1, meta2, ...]
 values = [
  	   [0] -> [value1, value2, ...]
           ...
           [N] -> [value1, value2, ...]
          ]
 colmap = { meta1->name => 0, meta2->name => 1, ..., metaN->name => N-1 }
 current; pointer to current location in data set.
	  used by next(), previous(), current()
 number of rows
}
===

result set methods:
 @values = results(order_by => meta->name, direction => asc|des)
	$value[N] = [value1, value2]; where value1 is the data that
	                              corresponds to the meta.

 @values = results_hashrefs(order_by => meta->name, direction => asc|des)
	$value[N] = { meta1->name => value1, meta2->name => value2 }

 @meta = get_columns()
 @meta = get_metadata()

 order_by($meta->name, asc|des); sets the sort order for results*()

=head2 Iterator interface (do later)

 reset(); reset current pointer to the beginning of the list

 sort($meta->name, asc|des); sort values by given column. Resets pointer

 next(); move the current pointer and return the result or undef if none
 next_hash(); same as above but return the result as a hash

 current(); return the current result
 current_hash()

 back(); move the current pointer back and return the result or undef
 back_hash()

How to add data to result set?

 add_meta(VUser::Meta)
 add_data([value1, value2, ...])
 add_data({meta1->name => value1, meta2->name => value2, ...})

=head1 BUGS

There are currently no checks to verify that the data added with add_data()
matches the data type specified with add_meta().

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE
 
 This file is part of vuser.
 
 vuser is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 vuser is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with vuser; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
