#
# WebFetch::Data::Store - WebFetch Embedding API top-level data store
#
# Copyright (c) 2009 Ian Kluft. This program is free software; you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License Version 3. See  http://www.webfetch.org/GPLv3.txt
#
# The WebFetch Embedding API manages the following data:
# * {data} - top level hash container (WebFetch::Data::Store)
#   * {fields} - array of field names
#   * {records} - array of data records (WebFetch::Data::Record)
#     * each record is an array of data fields in the order of the field names
#   * {wk_names} - hash of WebFetch well-known fields to actual field names
#   * {feed} - top-level arbitrary info about the feed
#

package WebFetch::Data::Store;

use strict;
use warnings;
use WebFetch;
use base qw( WebFetch );

# define exceptions/errors
use Exception::Class (
);

# no user-servicable parts beyond this point

=head1 NAME

WebFetch::Data::Store - Object for management of WebFetch data

=head1 SYNOPSIS

C<use WebFetch::Data::Store;>

C<$data = webfetch_obj-E<gt>data;
$data-E<gt>add_fields( "field1", "field2", ... );
$num = $data-E<gt>num_fields;
@field_names = $data-E<gt>get_fields;
$name = $data-E<gt>field_bynum( 3 );
$data-E<gt>add_wk_names( "title" =E<gt> "heading", "url" =E<gt> "link", ... );
$value = $data-E<gt>get_feed( $name );
$data-E<gt>set_feed( $name, $value );
$data-E<gt>add_record( $field1, $field2, ... ); # order corresponds to add_fields
$num = $data-E<gt>num_records;
$record = $data-E<gt>get_record( $n );
$data-E<gt>reset_pos;
$record = $data-E<gt>next_record;
$name = $data-E<gt>wk2fname( $wk_name );
$num = $data-E<gt>fname2fnum( $field_name );
$num = $data-E<gt>wk2fnum( $wk_name );
>

=head1 DESCRIPTION

This module provides access to the WebFetch data.
WebFetch instantiates the object for the input module.
The input module uses this to construct the data set from its input.
The output module uses the this to access the data and
produce its output object/format.

=cut

# initialization
sub init
{
	my $self = shift;
	$self->{fields} = [];
	$self->{findex} = {};
	$self->{records} = [];
	$self->{wk_names} = {};
	$self->{wkindex} = {};
	$self->{feed} = {};

	# signal WebFetch that Data subclasses do not provide a fetch function
	$self->{no_fetch} = 1;
	$self->SUPER::init( @_ );

	return $self;
}

=item $obj->add_fields( "field1", "field2", ... );

Add the field names in the order their values will appear in the data table.

=cut

# add field names
sub add_fields
{
	my $self = shift;
	my @fields = @_;
	my $field;
	foreach $field ( @fields ) {
		$self->{findex}{$field} = scalar @{$self->{fields}};
		push @{$self->{fields}}, $field;
	}
}

=item $num = $obj->num_fields;

Returns the number of fields/columns in the data.

=cut

# get number of fields
sub num_fields
{
	my $self = shift;
	return scalar @{$self->{fields}};
}

=item @field_names = $obj->get_fields;

Gets a list of the field names in the order their values appear in the data
table;

=cut

# get field names
sub get_fields
{
	my $self = shift;
	return keys %{$self->{fields}};
}

=item $field_name = $obj->field_bynum( $num );

Return a field name string based on the numeric position of the field.

=cut

# get field name by number
sub field_bynum
{
	my $self = shift;
	my $num = shift;
	return $self->{fields}[$num];
}

=item $obj->add_wk_names( "title" => "heading", "url" => "link", ... );

Add associations between WebFetch well-known field names, which allows
WebFetch to apply meaning to these fields, such as titles, dates and URLs.
The parameters are pairs of well-known and actual field names.
Running this function more than once will add to the existing associations
of well-known to actual field names.

=cut

# add well-known names
sub add_wk_names
{
	my $self = shift;
	my ( $wk_name, $field );

	while ( @_ >= 2 ) {
		$wk_name = shift;
		$field = shift;
		WebFetch::debug "add_wk_names $wk_name => $field";
		$self->{wk_names}{$wk_name} = $field;
		$self->{wkindex}{$wk_name} = $self->{findex}{$field};
	}
}

=item $value = $obj->get_feed( $name );

Get an item of per-feed data by name.

=cut

# get feed info
sub get_feed
{
	my $self = shift;
	my $name = shift;
	return (exists $self->{$name}) ? $self->{$name} : undef;
}

=item $obj->set_feed( $name, $value );

Set an item of per-feed data by name and value.

=cut

# set feed info
sub set_feed
{
	my $self = shift;
	my $name = shift;
	my $value = shift;
	my $retval = (exists $self->{$name}) ? $self->{$name} : undef;
	$self->{$name} = $value;
	return $retval;
}

=item $obj->add_record( $value1, $value2, $value3, ... );

Add a row to the end of the data table.  Values must correspond to the
positions of the field names that were provided earlier.

=cut

# add a data record
# this adds the field values in the same order the field names were added
sub add_record
{
	my $self = shift;
	push @{$self->{records}}, [ @_ ];
}

# TODO: add a function add_record_unordered( name => value, ... )
# less efficient, but may be OK for cases where that doesn't matter

=item $num = $obj->num_records;

Get the number of records/rows in the data table.

=cut

# get the number of data records
sub num_records
{
	my $self = shift;
	return scalar @{$self->{records}};
}

=item $record = get_record( $num );

Returns a WebFetch::Data::Record object for the row located
by the given row number in the data table.  The first row is numbered 0.
Calling this function does not affect the position used by the next_record
function.

=cut

# get a data record by index
sub get_record
{
	my $self = shift;
	my $n = shift;
	WebFetch::debug "get_record $n";
	require WebFetch::Data::Record;
	return WebFetch::Data::Record->new( $self, $n );
}

=item $obj->reset_pos;

Reset the position counter used by the next_record function back to the
beginning of the data table.

=cut

# reset iterator position
sub reset_pos
{
	my $self = shift;

	WebFetch::debug "reset_pos";
	delete $self->{pos};
}

=item $record = $obj->next_record;

The first call to this function returns the first record.
Each successive call to this function returns the following record until
the end of the data table.
After the last record, the function returns undef until
reset_pos is called to reset it back to the beginning.

=cut

# get next record
sub next_record
{
	my $self = shift;

	# initialize if necessary
	if ( !exists $self->{pos}) {
		$self->{pos} = 0;
	}
	WebFetch::debug "next_record n=".$self->{pos}." of "
		.scalar @{$self->{records}};

	# return undef if position is out of bounds
	( $self->{pos} < 0 ) and return undef;
	( $self->{pos} > scalar @{$self->{records}} - 1 ) and return undef;
	
	# get record
	return $self->get_record( $self->{pos}++ );
}

=item $obj->wk2fname( $wk )

Obtain a field name from a well-known name.

=cut

# convert well-known name to field name
sub wk2fname
{
	my $self = shift;
	my $wk = shift;

	WebFetch::debug "wk2fname $wk => ".(( exists $self->{wk_names}{$wk}) ? $self->{wk_names}{$wk} : "undef");
	return ( exists $self->{wk_names}{$wk})
		? $self->{wk_names}{$wk}
		: undef;
}

=item $obj->fname2fnum( $fname )

Obtain a field number from a field name.

=cut

# convert a field name to a field number
sub fname2fnum
{
	my $self = shift;
	my $fname = shift;

	WebFetch::debug "fname2fnum $fname => ".(( exists $self->{findex}{$fname}) ? $self->{findex}{$fname} : "undef" );
	return ( exists $self->{findex}{$fname})
		? $self->{findex}{$fname}
		: undef;
}

=item $obj->wk2fnum( $wk )

Obtain a field number from a well-known name.

=cut

# convert well-known name to field number
sub wk2fnum
{
	my $self = shift;
	my $wk = shift;

	WebFetch::debug "wk2fnum $wk => ".(( exists $self->{wkindex}{$wk}) ? $self->{wkindex}{$wk} : "undef" );
	return ( exists $self->{wkindex}{$wk})
		? $self->{wkindex}{$wk}
		: undef;
}

1;
__END__
=head1 AUTHOR

WebFetch was written by Ian Kluft
Send patches, bug reports, suggestions and questions to
C<maint@webfetch.org>.

=head1 SEE ALSO

L<WebFetch>, L<WebFetch::Data::Record>
