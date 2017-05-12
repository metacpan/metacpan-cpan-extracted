use strict;
use warnings;
package WWW::Sitemapper::Tree;
BEGIN {
  $WWW::Sitemapper::Tree::AUTHORITY = 'cpan:AJGB';
}
{
  $WWW::Sitemapper::Tree::VERSION = '1.121160';
}
#ABSTRACT: Tree structure of pages.

use Moose;
use WWW::Sitemapper::Types qw( tURI tDateTime );


has 'id' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => '0',
);


has 'uri' => (
    is => 'rw',
    isa => tURI,
    required => 1,
);

has '_base_uri' => (
    is => 'rw',
    isa => tURI,
);


has 'title' => (
    is => 'rw',
    isa => 'Str',
);


has 'last_modified' => (
    is => 'rw',
    isa => tDateTime,
    coerce => 1,
);


has 'nodes' => (
    traits => [qw( Array )],
    is => 'rw',
    isa => 'ArrayRef[WWW::Sitemapper::Tree]',
    default => sub { [] },
    handles => {
        children => 'elements',
        add_child => 'push',
    }
);

has '_dictionary' => (
    traits => [qw( Hash )],
    is => 'rw',
    isa => 'HashRef[ScalarRef]',
    default => sub { +{} },
    handles => {
        add_to_dictionary => 'set',
        fast_lookup => 'get',
        all_entries => 'values',
    }
);

has '_redirects' => (
    traits => [qw( Hash )],
    is => 'rw',
    isa => 'HashRef[Ref]',
    default => sub { +{} },
    handles => {
        store_redirect => 'set',
        find_redirect => 'get',
    },
);



sub find_node {
    my $self = shift;
    my $url = shift;

    if ( my $node = $self->fast_lookup( $url->as_string ) ) {
        return $$node;
    }
    return;
}


sub redirected_from {
    my $self = shift;
    my $url = shift;

    if ( my $node = $self->find_redirect( $url->as_string ) ) {
        return $$node;
    }
    return;
}


sub add_node {
    my $self = shift;
    my $link = shift;

    $link->id( join(':', $self->id, scalar @{ $self->nodes } ) );

    $self->add_child( $link );

    return $link;
}


sub loc {
    my $self = shift;

    return $self->_base_uri || $self->uri;
}



1;

__END__
=pod

=encoding utf-8

=head1 NAME

WWW::Sitemapper::Tree - Tree structure of pages.

=head1 VERSION

version 1.121160

=head1 ATTRIBUTES

=head2 id

Unique id of the node.

isa: C<Str>.

=head2 uri

URI object for page. Represents the link found on the web site - before any
redirections.

isa: L<WWW::Sitemapper::Types/"tURI">.

=head2 title

Title of page.

isa: C<Str>.

=head2 last_modified

Value of Last-modified header.

isa: L<WWW::Sitemapper::Types/"tDateTime">.

=head2 nodes

An array of all mapped links found on the page - represented by
L<WWW::Sitemapper::Tree>.

isa: C<ArrayRef[>L<WWW::Sitemapper::Tree>C<]>.

=head1 METHODS

=head2 find_node

    my $mapper = MyWebSite::Map->new(
        site => 'http://mywebsite.com/',
        status_storage => 'sitemap.data',
    );
    $mapper->restore_state();

    my $node = $mapper->tree->find_node( $uri );

Searches the cache for a node with matching uri.

Note: use it only at the root element L<WWW::Sitemapper/"tree">.

=head2 redirected_from

    my $parent = $mapper->tree->redirected_from( $uri );

Searches the redirects cache for a node with matching uri.

Note: use it only at the root element L<WWW::Sitemapper/"tree">.

=head2 add_node

    my $child = $parent->add_node(
        WWW::Sitemapper::Tree->new(
            uri => $uri,
        )
    );

Adds new node to C<$parent> object and returns child with id set.

=head2 loc

    print $node->loc;

Represents the base location of page (which may be different from node
L<"uri"> if there was a redirection).

=head2 children

    for my $child ( $node->children ) {
        ...
    }

Returns all children of the node.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<WWW::Sitemapper|WWW::Sitemapper>

=back

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

