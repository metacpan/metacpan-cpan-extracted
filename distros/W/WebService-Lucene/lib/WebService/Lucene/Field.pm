package WebService::Lucene::Field;

use strict;
use warnings;

use base qw( Class::Accessor::Fast );

my %info = (
    text => {
        stored    => 1,
        indexed   => 1,
        tokenized => 1
    },
    keyword => {
        stored    => 1,
        indexed   => 1,
        tokenized => 0
    },
    unindexed => {
        stored    => 1,
        indexed   => 0,
        tokenized => 0
    },
    unstored => {
        stored    => 0,
        indexed   => 1,
        tokenized => 1
    },
    sorted => {
        stored    => 0,
        indexed   => 1,
        tokenized => 0
    }
);

__PACKAGE__->mk_accessors( qw( name value type ) );

=head1 NAME

WebService::Lucene::Field - Object to represent a field in a document

=head1 SYNOPSIS

    $field = WebService::Lucene::Field->new( {
        name  => 'foo',
        value => 'bar',
        type  => 'text'
    } );
    
    # or via the 'text' method
    $field = WebService::Lucene::Field->text(
        name  => 'foo',
        value => 'bar'
    );

=head1 DESCRIPTION

=head1 METHODS

=head2 new( $options )

Creates a new field object from the options provided.

=head2 types( )

Returns the types of fields available.

=cut

sub types {
    return keys %info;
}

=head2 text( $name => $value )

Create a new text field.

=cut

sub text {
    return shift->_new_as( 'text', @_ );
}

=head2 keyword( $name => $value )

Create a new keyword field.

=cut

sub keyword {
    return shift->_new_as( 'keyword', @_ );
}

=head2 unindexed( $name => $value )

Creates a new unindexed field.

=cut

sub unindexed {
    return shift->_new_as( 'unindexed', @_ );
}

=head2 unstored( $name => $value )

Creates a new unstored field.

=cut

sub unstored {
    return shift->_new_as( 'unstored', @_ );
}

=head2 sorted( $name => $value )

Creates a new sorted field.

=cut

sub sorted {
    return shift->_new_as( 'sorted', @_ );
}

=head2 _new_as( $type, $name => $value )

A shorter way to generate a field object.

=cut

sub _new_as {
    return shift->new( { type => shift, name => shift, value => shift } );
}

=head2 is_stored( )

Will the field be stored in the index?

=cut

sub is_stored {
    return $info{ shift->type }->{ stored };
}

=head2 is_indexed( )

Will the field be indexed?

=cut

sub is_indexed {
    return $info{ shift->type }->{ indexed };
}

=head2 is_tokenized( )

Will the field be tokenized in the index?

=cut

sub is_tokenized {
    return $info{ shift->type }->{ tokenized };
}

=head2 get_info( [$type] )

Returns a hashref of info for the current or specified type.

=cut

sub get_info {
    my ( $self, $type ) = @_;

    $type ||= $self->type;

    return $info{ $type };
}

=head2 get_type( $info )

Given a hashref of information (stored, indexed, tokenzied)
it will return the type of field.

=cut

sub get_type {
    my ( $class, $args ) = @_;

    for my $type ( keys %info ) {
        my $data  = $info{ $type };
        my $match = 1;

        for ( keys %$data ) {
            $match = 0 && last
                unless !( $data->{ $_ } ^ ( $args->{ $_ } || 0 ) );
        }

        return $type if $match;
    }
}

=head2 name( [$name] )

Accessor for the field name.

=head2 value( [$value] )

Accessor for the field value.

=head2 type( [$type] )

Accessor for the field type.

=cut

=head1 AUTHORS

=over 4

=item * Brian Cassidy E<lt>brian.cassidy@nald.caE<gt>

=item * Adam Paynter E<lt>adam.paynter@nald.caE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2009 National Adult Literacy Database

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
