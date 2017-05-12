package WebService::Lucene;

use strict;
use warnings;

use base qw( WebService::Lucene::Client Class::Accessor::Fast );

use URI;
use Carp qw( croak );
use WebService::Lucene::Index;
use WebService::Lucene::XOXOParser;
use XML::LibXML;
use Scalar::Util ();

our $VERSION = '0.10';

__PACKAGE__->mk_accessors(
    qw(
        base_url indices_ref properties_ref title_info
        service_doc_fetched
        )
);

=head1 NAME

WebService::Lucene - Module to interface with the Lucene indexing webservice

=head1 SYNOPSIS

    # Connect to the web service
    $ws = WebService::Lucene->new( $url );
    
    # Create an index
    $ndex = $ws->create_index( $index );
    
    # Get a particular index
    $index = $ws->get_index( $name );
    
    # Index a document
    $document = $index->add_document( $document );
    
    # Get a document
    $document = $index->get_document( $id );
    
    # Delete the document
    $document->delete;
    
    # Search an index
    $results = $index->search( $query );
    
    # Get documents from search
    @documents = $results->documents;
    
    # Delete an index
    $index->delete;

=head1 DESCRIPTION

This module is a Perl API in to the Lucene indexing web service.
http://lucene-ws.net/

=head1 METHODS

=head2 new( $url )

This method will connect to the Lucene Web Service located at C<$url>.

    my $ws = WebService::Lucene->new( 'http://localhost:8080/lucene/' );

=cut

sub new {
    my ( $class, $url ) = @_;

    croak( "No URL specified" ) unless $url;

    if ( !ref $url ) {
        $url =~ s{/?$}{/};
        $url = URI->new( $url );
    }

    my $self = $class->SUPER::new;
    $self->base_url( $url );
    $self->indices_ref( {} );

    return $self;
}

=head2 base_url( [$url] )

Accessor for the base url of the service.

=head2 get_index( $name )

Retuens an L<WebService::Lucene::Index> object for C<$name>.

=cut

sub get_index {
    my ( $self, $name ) = @_;
    my $indices_ref = $self->indices_ref;

    return $name if Scalar::Util::blessed $name;

    if ( ref $name ) {
        $name = join( ',',
            map { Scalar::Util::blessed $_ ? $_->name : $_ } @$name );
    }

    if ( my $index = $indices_ref->{ $name } ) {
        return $index;
    }

    # make sure it ends in a slash
    my $urlname = $name;
    $urlname =~ s{/?$}{/};
    $indices_ref->{ $name } = WebService::Lucene::Index->new(
        URI->new_abs( $urlname, $self->base_url ) );

    return $indices_ref->{ $name };
}

=head2 indexes( )

Alias for C<indices>

=head2 indices( )

Returns an array of L<WebService::Lucene::Index> objects.

=cut

*indexes = \&indices;

sub indices {
    my $self = shift;

    if ( !$self->service_doc_fetched ) {
        $self->_fetch_service_document;
    }

    my $indices = $self->indices_ref;

    # filter out multi-indicies
    return map { $indices->{ $_ } } grep { $_ !~ /,/ } keys %$indices;
}

=head2 properties( [$properties] )

Hash reference to a list of properties for the service.

=cut

sub properties {
    my $self = shift;

    if ( !$self->properties_ref ) {
        $self->_fetch_service_properties;
    }

    return $self->properties_ref;
}

=head2 _fetch_service_properties( )

Grabs the C<service.properties> documents and sends the contents
to C<_parse_service_properties>.

=cut

sub _fetch_service_properties {
    my ( $self ) = @_;
    my $entry = $self->getEntry(
        URI->new_abs( 'service.properties', $self->base_url ) );
    $self->_parse_service_properties( $entry->content->body );
}

=head2 _parse_service_properties( $xml )

Parses the XML and populates the object's C<properties>

=cut

sub _parse_service_properties {
    my ( $self, $xml ) = @_;

    $self->properties_ref(
        {   map { $_->{ name } => $_->{ value } }
                WebService::Lucene::XOXOParser->parse( $xml )
        }
    );
}

=head2 _fetch_service_document( )

Connects to the service url and passes the contents on to
C<_parse_service_document>.

=cut

sub _fetch_service_document {
    my ( $self ) = @_;
    $self->_parse_service_document(
        $self->_fetch_content( $self->base_url ) );
    $self->service_doc_fetched( 1 );
}

=head2 _parse_service_document( $xml )

Parses the Atom Publishing Protocol introspection document and populates
the service's C<indices>.

=cut

sub _parse_service_document {
    my ( $self, $xml ) = @_;

    my $parser  = XML::LibXML->new;
    my $doc     = $parser->parse_string( $xml );
    my $indices = $self->indices_ref;

    my ( $workspace )
        = $doc->documentElement->getChildrenByTagName( 'workspace' );

    my( $title ) = $workspace->getElementsByLocalName( 'title' );
    $self->title_info( $title->textContent );

    for my $collection ( $workspace->getChildrenByTagName( 'collection' ) ) {
        my $url = $collection->getAttributeNode( 'href' )->value;
        my ( $name ) = $url =~ m{/([^/]+)/?$};
        next if exists $indices->{ $name };
        $indices->{ $name } = WebService::Lucene::Index->new( $url );
    }
}

=head2 title( [$title] )

Accessor for the title of the service.

=cut

sub title {
    my ( $self ) = @_;

    if ( !$self->service_doc_fetched ) {
        $self->_fetch_service_document;
    }

    return $self->title_info;
}

=head2 _fetch_content( $url )

Shortcut for fetching the content at C<$url>.

=cut

sub _fetch_content {
    my ( $self, $url ) = @_;

    my $response = $self->{ ua }->get( $url );

    return $response->content;
}

=head2 create_index( $name )

Creates the index on the server and returns the
L<WebService::Lucene::Index> object.

=cut

sub create_index {
    my ( $self, $name ) = @_;
    my $index = $self->get_index( $name );
    return $index->create;
}

=head2 delete_index( $name )

Deletes an index.

=cut

sub delete_index {
    my ( $self, $name ) = @_;
    my $index = $self->get_index( $name );
    return $index->delete;
}

=head2 update( )

Updates the C<service.properties> document.

=cut

sub update {
    my ( $self ) = @_;
    $self->updateEntry( URI->new_abs( 'service.properties', $self->base_url ),
        $self->_properties_as_entry );
}

=head2 _properties_as_entry( )

Genereates an L<XML::Atom::Entry> suitable for updating
the C<service.properties> document.

=cut

sub _properties_as_entry {
    my ( $self ) = @_;

    my $entry = XML::Atom::Entry->new;
    $entry->title( 'service.properties' );

    my $props = $self->properties_ref;
    my @properties = map +{ name => $_, value => $props->{ $_ } },
        keys %$props;
    my $xml = WebService::Lucene::XOXOParser->construct( @properties );

    $entry->content( $xml );
    $entry->content->type( 'xhtml' );

    return $entry;
}

=head2 search( $indices, $query, [$params] )

Searches one or more indices for C<$query>. Returns an
L<WebService::Lucene::Results> object.

    my $results = $ws->search( [ 'index1', 'index2' ], 'foo' );

=cut

sub search {
    my ( $self, $name, @rest ) = @_;
    return $self->get_index( $name )->search( @rest );
}

=head2 facets( $indices, [$params] )

Gets facets for one or more indices. Returns an
L<WebService::Lucene::Results> object.

    my $results = $ws->facets( [ 'index1', 'index2' ] );

=cut

sub facets {
    my ( $self, $name, @rest ) = @_;
    return $self->get_index( $name )->facets( @rest );
}

=head1 SEE ALSO

=over 4

=item * L<XML::Atom::Client>

=item * L<WWW::OpenSearch>

=item * http://lucene-ws.net/

=back

=head1 AUTHORS

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

Adam Paynter E<lt>adapay@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2009 National Adult Literacy Database

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
