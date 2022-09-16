# WebFetch::Data::Store
# ABSTRACT: WebFetch Embedding API top-level data store
#
# Copyright (c) 2009-2022 Ian Kluft. This program is free software; you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License Version 3. See  https://www.gnu.org/licenses/gpl-3.0-standalone.html
#
# The WebFetch Embedding API manages the following data:
# * {data} - top level hash container (WebFetch::Data::Store)
#   * {fields} - array of field names
#   * {records} - array of data records (WebFetch::Data::Record)
#     * each record is an array of data fields in the order of the field names
#   * {wk_names} - hash of WebFetch well-known fields to actual field names
#   * {feed} - top-level arbitrary info about the feed
#

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use strict;
use warnings;
use utf8;
## use critic (Modules::RequireExplicitPackage)

package WebFetch::Data::Store;
$WebFetch::Data::Store::VERSION = '0.15.1';
use strict;
use warnings;
use WebFetch;
use base qw( WebFetch );

# define exceptions/errors
use Exception::Class ();

# no user-servicable parts beyond this point

# instantiate new object
sub new
{
    my ( $class, @params ) = @_;
    my $self = {};
    bless $self, $class;
    $self->init(@params);
    return $self;
}

# initialization
sub init
{
    my ( $self, @params ) = @_;
    $self->{fields}   = [];
    $self->{findex}   = {};
    $self->{records}  = [];
    $self->{wk_names} = {};
    $self->{wkindex}  = {};
    $self->{feed}     = {};

    # signal WebFetch that Data subclasses do not provide a fetch function
    $self->{no_fetch} = 1;
    $self->SUPER::init(@params);

    return $self;
}

# add field names
sub add_fields
{
    my ( $self, @fields ) = @_;
    foreach my $field (@fields) {
        $self->{findex}{$field} = scalar @{ $self->{fields} };
        push @{ $self->{fields} }, $field;
    }
    return;
}

# get number of fields
sub num_fields
{
    my $self = shift;
    return scalar @{ $self->{fields} };
}

# get field names
sub get_fields
{
    my $self = shift;
    return keys %{ $self->{fields} };
}

# get field name by number
sub field_bynum
{
    my $self = shift;
    my $num  = shift;
    return $self->{fields}[$num];
}

# add well-known names
sub add_wk_names
{
    my $self = shift;
    my ( $wk_name, $field );

    while ( @_ >= 2 ) {
        $wk_name = shift;
        $field   = shift;
        WebFetch::debug "add_wk_names $wk_name => $field";
        $self->{wk_names}{$wk_name} = $field;
        $self->{wkindex}{$wk_name}  = $self->{findex}{$field};
    }
    return;
}

# get feed info
sub get_feed
{
    my $self = shift;
    my $name = shift;
    return ( exists $self->{$name} ) ? $self->{$name} : undef;
}

# set feed info
sub set_feed
{
    my $self   = shift;
    my $name   = shift;
    my $value  = shift;
    my $retval = ( exists $self->{$name} ) ? $self->{$name} : undef;
    $self->{$name} = $value;
    return $retval;
}

# add a data record
# this adds the field values in the same order the field names were added
sub add_record
{
    my ( $self, @args ) = @_;
    push @{ $self->{records} }, [@args];
    return;
}

# TODO: add a function add_record_unordered( name => value, ... )
# less efficient, but may be OK for cases where that doesn't matter

# get the number of data records
sub num_records
{
    my $self = shift;
    return scalar @{ $self->{records} };
}

# get a data record by index
sub get_record
{
    my $self = shift;
    my $n    = shift;
    WebFetch::debug "get_record $n";
    require WebFetch::Data::Record;
    return WebFetch::Data::Record->new( $self, $n );
}

# reset iterator position
sub reset_pos
{
    my $self = shift;

    WebFetch::debug "reset_pos";
    delete $self->{pos};
    return;
}

# get next record
sub next_record
{
    my $self = shift;

    # initialize if necessary
    if ( !exists $self->{pos} ) {
        $self->{pos} = 0;
    }
    WebFetch::debug "next_record n=" . $self->{pos} . " of " . scalar @{ $self->{records} };

    # return undef if position is out of bounds
    ( $self->{pos} < 0 ) and return;
    ( $self->{pos} > scalar @{ $self->{records} } - 1 ) and return;

    # get record
    return $self->get_record( $self->{pos}++ );
}

# convert well-known name to field name
sub wk2fname
{
    my $self = shift;
    my $wk   = shift;

    WebFetch::debug "wk2fname $wk => " . ( ( exists $self->{wk_names}{$wk} ) ? $self->{wk_names}{$wk} : "undef" );
    return ( exists $self->{wk_names}{$wk} )
        ? $self->{wk_names}{$wk}
        : undef;
}

# convert a field name to a field number
sub fname2fnum
{
    my $self  = shift;
    my $fname = shift;

    WebFetch::debug "fname2fnum $fname => "
        . (
        ( exists $self->{findex}{$fname} )
        ? $self->{findex}{$fname}
        : "undef"
        );
    return ( exists $self->{findex}{$fname} )
        ? $self->{findex}{$fname}
        : undef;
}

# convert well-known name to field number
sub wk2fnum
{
    my $self = shift;
    my $wk   = shift;

    WebFetch::debug "wk2fnum $wk => " . ( ( exists $self->{wkindex}{$wk} ) ? $self->{wkindex}{$wk} : "undef" );
    return ( exists $self->{wkindex}{$wk} )
        ? $self->{wkindex}{$wk}
        : undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebFetch::Data::Store - WebFetch Embedding API top-level data store

=head1 VERSION

version 0.15.1

=head1 SYNOPSIS

    use WebFetch::Data::Store;

    $data = webfetch_obj->data;
    $data->add_fields( "field1", "field2", ... );
    $num = $data->num_fields;
    @field_names = $data->get_fields;
    $name = $data->field_bynum( 3 );
    $data->add_wk_names( "title" => "heading", "url" => "link", ... );
    $value = $data->get_feed( $name );
    $data->set_feed( $name, $value );
    $data->add_record( $field1, $field2, ... ); # order corresponds to add_fields
    $num = $data->num_records;
    $record = $data->get_record( $n );
    $data->reset_pos;
    $record = $data->next_record;
    $name = $data->wk2fname( $wk_name );
    $num = $data->fname2fnum( $field_name );
    $num = $data->wk2fnum( $wk_name );

=head1 DESCRIPTION

This module provides access to the WebFetch data.
WebFetch instantiates the object for the input module.
The input module uses this to construct the data set from its input.
The output module uses the this to access the data and
produce its output object/format.

=over 4

=item $obj->add_fields( "field1", "field2", ... );

Add the field names in the order their values will appear in the data table.

=item $num = $obj->num_fields;

Returns the number of fields/columns in the data.

=item @field_names = $obj->get_fields;

Gets a list of the field names in the order their values appear in the data
table;

=item $field_name = $obj->field_bynum( $num );

Return a field name string based on the numeric position of the field.

=item $obj->add_wk_names( "title" => "heading", "url" => "link", ... );

Add associations between WebFetch well-known field names, which allows
WebFetch to apply meaning to these fields, such as titles, dates and URLs.
The parameters are pairs of well-known and actual field names.
Running this function more than once will add to the existing associations
of well-known to actual field names.

=item $value = $obj->get_feed( $name );

Get an item of per-feed data by name.

=item $obj->set_feed( $name, $value );

Set an item of per-feed data by name and value.

=item $obj->add_record( $value1, $value2, $value3, ... );

Add a row to the end of the data table.  Values must correspond to the
positions of the field names that were provided earlier.

=item $num = $obj->num_records;

Get the number of records/rows in the data table.

=item $record = get_record( $num );

Returns a WebFetch::Data::Record object for the row located
by the given row number in the data table.  The first row is numbered 0.
Calling this function does not affect the position used by the next_record
function.

=item $obj->reset_pos;

Reset the position counter used by the next_record function back to the
beginning of the data table.

=item $record = $obj->next_record;

The first call to this function returns the first record.
Each successive call to this function returns the following record until
the end of the data table.
After the last record, the function returns undef until
reset_pos is called to reset it back to the beginning.

=item $obj->wk2fname( $wk )

Obtain a field name from a well-known name.

=item $obj->fname2fnum( $fname )

Obtain a field number from a field name.

=item $obj->wk2fnum( $wk )

Obtain a field number from a well-known name.

=back

=head1 SEE ALSO

L<WebFetch>, L<WebFetch::Data::Record>
L<https://github.com/ikluft/WebFetch>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/WebFetch/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/WebFetch/pulls>

=head1 AUTHOR

Ian Kluft <https://github.com/ikluft>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998-2022 by Ian Kluft.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
