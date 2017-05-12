package WebService::Lucene::Index;

use strict;
use warnings;

use base qw( WebService::Lucene::Client Class::Accessor::Fast );

use URI;
use Carp qw( croak );
use WebService::Lucene::XOXOParser;
use WebService::Lucene::Results;
use WebService::Lucene::Document;
use XML::Atom::Entry;
use HTTP::Request;
use WWW::OpenSearch;
use Encode ();

__PACKAGE__->mk_accessors(
    qw(
        base_url name properties_ref _opensearch_client
        )
);

=head1 NAME

WebService::Lucene::Index - Object to represent a Lucene Index

=head1 SYNOPSIS

    # Index @ $url
    $index = WebService::Lucene::Index->new( $url );
    
    # Get most recently modified documents
    $results = $index->list;
    
    # Search the index
    $results = $index->search( 'foo' );
    
    # Get a document
    $doc = $index->get_document( $id );
    
    # Create a document
    $doc = $index->create_document( $doc );
    
    # Delete the index
    $index->delete;

=head1 DESCRIPTION

The module represents a Lucene Index.

=head1 METHODS

=head2 new( $url )

Create a new Index object located at C<$url>. Note, this will
not actually create the index -- see C<create> to do that.

=cut

sub new {
    my ( $class, $url ) = @_;

    croak( "No URL specified" ) unless $url;

    if ( !ref $url ) {
        $url =~ s{/?$}{/};
        $url = URI->new( $url );
    }

    my ( $name ) = $url =~ m{/([^/]+)/?$};

    my $self = $class->SUPER::new;
    $self->base_url( $url );
    $self->name( $name );

    return $self;
}

=head2 base_url( [$url] )

Accessor for the index's url.

=head2 name( [$name] )

Accessor for the index's name.

=head2 properties( [$properties] )

Accessor for the index's properties.

=cut

sub properties {
    my $self = shift;

    if ( !$self->properties_ref ) {
        $self->_fetch_index_properties;
    }

    return $self->properties_ref;
}

=head2 _fetch_index_properties( )

Fetches the C<index.properties> entry and sends the contents
to C<_parse_index_properties>.

=cut

sub _fetch_index_properties {
    my ( $self ) = @_;
    my $entry = $self->getEntry(
        URI->new_abs( 'index.properties', $self->base_url ) );
    $self->_parse_index_properties( $entry->content->body );
}

=head2 _parse_index_properties( $xml )

Parses the XOXO document and sets the C<properties> accessor.

=cut

sub _parse_index_properties {
    my ( $self, $xml ) = @_;

    $self->properties_ref(
        {   map { $_->{ name } => $_->{ value } }
                WebService::Lucene::XOXOParser->parse( $xml )
        }
    );
}

=head2 delete( )

Deletes the current index.

=cut

sub delete {
    my ( $self ) = @_;
    $self->deleteEntry( $self->base_url );
}

=head2 update( )

Updates the C<index.properties> file with the current set of properties.

=cut

sub update {
    my ( $self ) = @_;
    $self->updateEntry( URI->new_abs( 'index.properties', $self->base_url ),
        $self->_properties_as_entry );
}

=head2 facets( $facets, [$params] )

Give a facet (or set of facets as an array reference), it will
return a L<WebService::Lucene::Results> object with their details. You
can pass any number of parameters that will be serialized as query
string arguments.

=cut

sub facets {
    my ( $self, $facet, $params ) = @_;

    my $name = ref $facet ? join( ',', @$facet ) : $facet;
    my $client = $self->opensearch_client;

    my $os_url = $client->description->get_best_url;
    my $url    = $os_url->prepare_query( $params );
    $url->path( $url->path . "/facets/$name" );

    return WebService::Lucene::Results->new_from_feed(
        $self->getFeed( $url ) );
}

=head2 list( [$params] )

Returns a L<WebService::Lucene::Results> object with a list of the recently updated documents.

=cut

sub list {
    my ( $self, $params ) = @_;
    my $url = $self->base_url->clone;
    $url->query_form( $params ) if $params;
    return WebService::Lucene::Results->new_from_feed(
        $self->getFeed( $url ) );
}

=head2 optimize( )

Optimizes the index.

=cut

sub optimize {
    my ( $self ) = @_;
    my $request = HTTP::Request->new( PUT => $self->base_url . '?optimize' );
    return $self->make_request( $request );
}

=head2 create( )

Sends a create query to the server for the given index.

=cut

sub create {
    my ( $self ) = @_;
    my $name     = $self->name;
    my $url      = $self->base_url;

    $url =~ s{$name/?$}{};

    $self->createEntry( $url, $self->_properties_as_entry );

    return $self;
}

=head2 add_document( $document )

Adds C<$document> to the index.

=cut

sub add_document {
    my ( $self, $document ) = @_;
    $document->base_url( URI->new_abs( 'new', $self->base_url ) );
    return $document->create;
}

=head2 get_document( $id )

Returns a L<WebService::Lucene::Document>.

=cut

sub get_document {
    my ( $self, $id ) = @_;
    my $entry = $self->getEntry( URI->new_abs( $id, $self->base_url ) );

    return WebService::Lucene::Document->new_from_entry( $entry );
}

=head2 delete_document( $id )

Deletes a document from the index

=cut

sub delete_document {
    my ( $self, $id ) = @_;
    my $document = WebService::Lucene::Document->new;

    $document->base_url( URI->new_abs( $id, $self->base_url ) );
    return $document->delete;
}

=head2 _properties_as_entry( )

Constructs an L<XML::Atom::Entry> object representing the index's properties.

=cut

sub _properties_as_entry {
    my ( $self ) = @_;

    my $entry = XML::Atom::Entry->new;
    $entry->title( $self->name );

    my $props = $self->properties_ref;
    my @properties = map +{ name => $_, value => $props->{ $_ } },
        keys %$props;
    my $xml = WebService::Lucene::XOXOParser->construct( @properties );

    $entry->content( $xml );
    $entry->content->type( 'xhtml' );

    return $entry;
}

=head2 opensearch_client( )

returns an WWW::OpenSearch object for the index.

=cut

sub opensearch_client {
    my ( $self ) = @_;

    if ( !$self->_opensearch_client ) {
        $self->_opensearch_client(
            WWW::OpenSearch->new(
                URI->new_abs( 'opensearchdescription.xml', $self->base_url )
            )
        );
    }

    return $self->_opensearch_client;
}

=head2 search( $query, [$params] )

Searches the index for C<$query>. Pass any additional parameters as
a hashref.

=cut

sub search {
    my ( $self, $query, $params ) = @_;

    my $client = $self->opensearch_client;

    Encode::_utf8_off( $query );
    my $response = $client->search( $query, $params );
    Encode::_utf8_on( $query );

    return WebService::Lucene::Results->new_from_opensearch( $response );
}

=head2 exists( )

True if the index exists on the server, otherwise false is returned.

=cut

sub exists {
    my ( $self ) = @_;
    my $request = HTTP::Request->new( HEAD => $self->base_url );
    my $response = eval { $self->make_request( $request ); };

    if ( my $e = WebService::Lucene::Exception->caught ) {
        return 0 if $e->response->code eq '404';
        $e->rethrow;
    }

    return 1;
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
