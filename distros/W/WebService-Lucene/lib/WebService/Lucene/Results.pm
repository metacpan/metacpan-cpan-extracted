package WebService::Lucene::Results;

use strict;
use warnings;

use base qw( WebService::Lucene::Client Class::Accessor::Fast );

use WebService::Lucene::Document;
use WebService::Lucene::Iterator;
use WebService::Lucene::Exception;
use Encode qw();
use XML::Atom::Util;

use Carp;

__PACKAGE__->mk_accessors( qw( pager documents_ref object ) );

=head1 NAME

WebService::Lucene::Results - Results from a search or list operation

=head1 SYNOPSIS

    # documents
    @docs = $results->documents;
    
    # iterator
    $docs = $results->documents;
    
    # Data::Page object
    $pager = $results->pager;
    
    # next page
    $results = $results->next_page;
    
    # previous page
    $results = $results->previous_page;

=head1 DESCRIPTION

Wraps a list of documents and a L<Data::Page> object.

=head1 METHODS

=head2 new( )

Creates an empty results object.

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new;

    $self->documents_ref( [] );

    return $self;
}

=head2 new_from_feed( $feed )

Generates a results object from an L<XML::Atom::Feed> object.

=cut

sub new_from_feed {
    my ( $class, $object ) = @_;
    $class = ref $class if ref $class;
    my $self    = $class->new;
    my @entries = $object->entries;

    $self->documents_ref( [ map { $_->{ entry } || $_ } @entries ] );
    $self->object( $object );
    return $self;
}

=head2 new_from_opensearch( $opensearch )

Generates a results object from an L<WWW::OpenSearch::Response> object.

=cut

sub new_from_opensearch {
    my ( $class, $object ) = @_;

    if ( !$object->is_success ) {
        WebService::Lucene::Exception->throw( $object );
    }

    my $self = $class->new_from_feed( $object->feed );

    $self->pager( $object->pager );
    $self->object( $object );

    return $self;
}

=head2 object( [$object] )

Accessor for the original results object.

=head2 pager( [$pager] )

Accessor for the L<Data::Page> object.

=head2 documents_ref( [$documents] )

Accessor for an array ref of documents.

=head2 documents( )

Returns an interator in scalar context or an array of documents
in list context.

=cut

sub documents {
    my $self = shift;

    if ( wantarray ) {
        my @documents;
        for ( @{ $self->documents_ref } ) {
            push @documents,
                WebService::Lucene::Document->new_from_entry( $_ );
        }

        return @documents;
    }
    else {
        return WebService::Lucene::Iterator->new( $self->documents_ref );
    }
}

=head2 next_page( )

Goes to the next page of results.

=cut

sub next_page {
    my $self   = shift;
    my $object = $self->object;

    if ( $object->can( 'next_page' ) ) {
        return $self->new_from_opensearch( $object->next_page );
    }

    return $self->_fetch( $self->_get_link( 'next' ) );
}

=head2 previous_page( )

Goes to the previous page of results.

=cut

sub previous_page {
    my $self   = shift;
    my $object = $self->object;

    if ( $object->can( 'previous_page' ) ) {
        return $self->new_from_opensearch( $object->previous_page );
    }

    return $self->_fetch( $self->_get_link( 'previous' ) );
}

=head2 suggestion

Returns the C<opensearch:Query> field with C<rel="correction"> if it exists.
In list context, returns the full list. In scalar context only the first
suggestion is returned.

=head2 suggestions

Alias for C<suggestion()>.

=cut

*suggestions = \&suggestion;

sub suggestion {
    my $self = shift;
    return unless $self->object->can( 'feed' );

    my @vals;
    for ( $self->_os_nodelist( 'Query' ) ) {
        next unless $_->getAttribute( 'rel' ) eq 'correction';
        my $val = $_->getAttribute( 'searchTerms' );
        Encode::_utf8_on( $val );
        push @vals, $val;
    }
    return wantarray ? @vals : $vals[ 0 ];
}

sub _os_nodelist {
    my $self   = shift;
    my $elem   = shift;
    my $object = $self->object;
    my $ns     = $object->request->opensearch_url->ns;

    return XML::Atom::Util::nodelist( $object->feed->{ atom }->elem, $ns,
        $elem );
}

=head2 _get_link( $type )

Attempts to get a link tag of type C<$type> from an Atom feed.

=cut

sub _get_link {
    my $self = shift;
    my $type = shift;
    my $feed = $self->object;

    return unless $feed;

    for ( $feed->link ) {
        return $_->href if $_->rel eq $type;
    }
}

=head2 _fetch( $url )

Attempts to get an Atom feed from C<$url> and send it
to C<new_from_feed>.

=cut

sub _fetch {
    my $self = shift;
    my $url  = shift;

    return undef unless $url;

    my $feed = $self->getFeed( $url );

    croak "Error getting list: " . $self->errstr unless $feed;

    return $self->new_from_feed( $feed );
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
