package WebService::Lucene::Document;

use strict;
use warnings;

use base qw( WebService::Lucene::Client Class::Accessor::Fast );

use WebService::Lucene::Field;
use WebService::Lucene::XOXOParser;
use XML::Atom::Entry;

__PACKAGE__->mk_accessors( qw( fields_ref base_url title relevance ) );

BEGIN {
    for my $type ( WebService::Lucene::Field->types ) {
        no strict 'refs';
        *{ __PACKAGE__ . "\::add_$type" } = sub {
            shift->add( WebService::Lucene::Field->$type( @_ ) );
            }
    }
}

=head1 NAME

WebService::Lucene::Document - Object to represent a Lucene Document

=head1 SYNOPSIS

    # Create a new document
    $doc = WebService::Lucene::Document->new;
    
    # add a field
    $doc->add( $field );

=head1 DESCRIPTION

Object to represent a Lucene Document.

=head1 METHODS

=head2 new( )

Creates an empty document.

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new;

    $self->clear_fields;

    return $self;
}

=head2 create()

Sends a create request for this document.

=cut

sub create {
    my ( $self ) = @_;
    my $url = $self->base_url;

    $url =~ s{[^/]+/?$}{};

    my $new_url = $self->createEntry( $url, $self->as_entry );
    $self->base_url( $new_url );

    return $self;
}

=head2 new_from_entry( $entry )

Takes an L<XML::Atom::Entry> and constructs a new object.

=cut

sub new_from_entry {
    my ( $class, $entry ) = @_;
    my $self = $class->new;

    if ( $entry->link ) {
        $self->base_url( $entry->link->href );
    }

    $self->relevance(
        $entry->get( 'http://a9.com/-/opensearch/extensions/relevance/1.0/', 'score' ) );
    $self->title( $entry->title );
    my $content = $entry->content->body;

    my @properties = WebService::Lucene::XOXOParser->parse( $content );

    if ( @properties and $properties[ 0 ]->{ class } ) {
        for my $property ( @properties ) {
            my %attrs = map { $_ => 1 } split( / /, $property->{ class } );
            my $method
                = 'add_' . WebService::Lucene::Field->get_type( \%attrs );
            $self->$method( map { $property->{ $_ } } qw( name value ) );
        }
    }
    else {
        $self->fields_ref(
            {   $self->title =>
                    [ map { $_->{ name } => $_->{ value } } @properties ]
            }
        );
    }

    return $self;
}

=head2 add( @fields )

Adds each field to the document.

=cut

sub add {
    my $self   = shift;
    my $fields = $self->fields_ref;

    while ( my $field = shift ) {
        my $name = $field->name;
        unless ( exists $fields->{ $name } ) {
            $fields->{ $name } = [];
        }
        unless ( $self->can( $name ) ) {
            no strict 'refs';
            *{ ref( $self ) . "\::$name" } = _field_accessor( $name );
        }

        push @{ $fields->{ $name } }, $field;
    }
}

=head2 add_keyword( $name => $value )

Auto-generated shortcuts to add a "keyword" field.

=head2 add_sorted $name => $value )

Auto-generated shortcuts to add a "sorted" field.

=head2 add_text( $name => $value )

Auto-generated shortcuts to add a "keyword" field.

=head2 add_unindexed( $name => $value )

Auto-generated shortcuts to add a "keyword" field.

=head2 add_unstored( $name => $value )

Auto-generated shortcuts to add a "keyword" field.

=head2 title( [$title] )

The title of the document, set from search or listing results.

=head2 relevance( [$relevance] )

A floating point number (0..1) set from search results.

=head2 fields_ref( [$fields] )

A name-keyed hashref of field objects.

=head2 facets()

Technically an alias for fields. But should only be used when fetching
facet results.

=cut

*facets = \&fields;

=head2 get( [$name] )

Alias for C<fields>.

=cut

*get = \&fields;

=head2 fields( [$name] )

Returns all fields named <$name> or all fields if no name 
is specified.

=cut

sub fields {
    my $self      = shift;
    my $name      = shift;
    my $fieldsref = $self->fields_ref;

    if ( $name ) {
        my $fields = $fieldsref->{ $name };
        return () unless defined $fields;
        return wantarray ? @$fields : $fields->[ 0 ];
    }

    return map { @{ $fieldsref->{ $_ } } } keys %$fieldsref;
}

=head2 clear_fields( )

Removes all fields from this document

=cut

sub clear_fields {
    shift->fields_ref( {} );
}

=head2 remove_field( $field )

Remove a particular field from the document

=cut

sub remove_field {
    my $self  = shift;
    my $field = shift;

    {
        no strict 'refs';
        undef *{ ref( $self ) . "\::$field" };
    }

    return delete $self->fields_ref->{ $field };
}

=head2 as_entry( )

Generates an L<XML::Atom::Entry> object for the current document.

=cut

sub as_entry {
    my ( $self ) = @_;

    my $entry = XML::Atom::Entry->new;
    $entry->title( $self->title || 'New Entry' );

    my @properties;
    for my $field ( $self->fields ) {
        my $types = $field->get_info;

        push @properties,
            {
            name  => $field->name,
            value => $field->value,
            class => join( ' ', grep { $types->{ $_ } } keys %$types )
            };
    }
    my $xml = WebService::Lucene::XOXOParser->construct( @properties );

    $entry->content( $xml );
    $entry->content->type( 'xhtml' );

    return $entry;

}

=head2 update( )

Updates the document in the index.

=cut

sub update {
    my ( $self ) = @_;
    $self->updateEntry( $self->base_url, $self->as_entry );
}

=head2 delete( )

Delete the document from the index.

=cut

sub delete {
    my ( $self ) = @_;
    $self->deleteEntry( $self->base_url );
}

=head2 _field_accessor( $name )

Generates a closure for accessing a field.

=cut

sub _field_accessor {
    my $name = shift;
    return sub {
        my $self   = shift;
        my $fields = $self->fields_ref->{ $name };

        return unless defined $fields;

        my @values
            = map { $_->value } ( wantarray ? @$fields : $fields->[ 0 ] );
        return wantarray ? @values : $values[ 0 ];
        }
}

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
