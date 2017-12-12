package Yancy::Controller::Yancy;
our $VERSION = '0.004';
# ABSTRACT: A simple REST controller for Mojolicious

#pod =head1 DESCRIPTION
#pod
#pod This module contains the routes that L<Yancy> uses to work with the
#pod backend data.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Yancy>, L<Mojolicious::Controller>
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Controller';
use v5.24;
use experimental qw( signatures postderef );

#pod =method list_items
#pod
#pod List the items in a collection. The collection name should be in the
#pod stash key C<collection>. C<limit> and C<offset> may be provided as query
#pod parameters.
#pod
#pod =cut

sub list_items( $c ) {
    return unless $c->openapi->valid_input;
    my $args = $c->validation->output;
    my %opt = (
        limit => $args->{limit},
        offset => $args->{offset},
    );
    return $c->render(
        status => 200,
        openapi => $c->yancy->backend->list( $c->stash( 'collection' ), {}, \%opt ),
    );
}

#pod =method add_item
#pod
#pod Add a new item to the collection. The new item should be in the request
#pod body as JSON.
#pod
#pod =cut

sub add_item( $c ) {
    return unless $c->openapi->valid_input;
    return $c->render(
        status => 201,
        openapi => $c->yancy->backend->create( $c->stash( 'collection' ), $c->req->json ),
    );
}

#pod =method get_item
#pod
#pod Get a single item from a collection. The collection should be in the
#pod stash key C<collection>, and the item's ID in the stash key C<id>.
#pod
#pod =cut

sub get_item( $c ) {
    return unless $c->openapi->valid_input;
    my $args = $c->validation->output;
    my $id = $args->{ $c->stash( 'id_field' ) };
    return $c->render(
        status => 200,
        openapi => $c->yancy->backend->get( $c->stash( 'collection' ), $id ),
    );
}

#pod =method set_item
#pod
#pod Update an item in a collection. The collection should be in the stash
#pod key C<collection>, and the item's ID in the stash key C<id>. The updated
#pod item should be in the request body as JSON.
#pod
#pod =cut

sub set_item( $c ) {
    return unless $c->openapi->valid_input;
    my $args = $c->validation->output;
    my $id = $args->{ $c->stash( 'id_field' ) };
    $c->yancy->backend->set( $c->stash( 'collection' ), $id, $c->req->json );
    return $c->render(
        status => 200,
        openapi => $c->yancy->backend->get( $c->stash( 'collection' ), $id ),
    );
}

#pod =method delete_item
#pod
#pod Delete an item from a collection. The collection name should be in the
#pod stash key C<collection>. The ID of the item should be in the stash key
#pod C<id>.
#pod
#pod =cut

sub delete_item( $c ) {
    return unless $c->openapi->valid_input;
    my $args = $c->validation->output;
    my $id = $args->{ $c->stash( 'id_field' ) };
    $c->yancy->backend->delete( $c->stash( 'collection' ), $id );
    return $c->rendered( 204 );
}

1;

__END__

=pod

=head1 NAME

Yancy::Controller::Yancy - A simple REST controller for Mojolicious

=head1 VERSION

version 0.004

=head1 DESCRIPTION

This module contains the routes that L<Yancy> uses to work with the
backend data.

=head1 METHODS

=head2 list_items

List the items in a collection. The collection name should be in the
stash key C<collection>. C<limit> and C<offset> may be provided as query
parameters.

=head2 add_item

Add a new item to the collection. The new item should be in the request
body as JSON.

=head2 get_item

Get a single item from a collection. The collection should be in the
stash key C<collection>, and the item's ID in the stash key C<id>.

=head2 set_item

Update an item in a collection. The collection should be in the stash
key C<collection>, and the item's ID in the stash key C<id>. The updated
item should be in the request body as JSON.

=head2 delete_item

Delete an item from a collection. The collection name should be in the
stash key C<collection>. The ID of the item should be in the stash key
C<id>.

=head1 SEE ALSO

L<Yancy>, L<Mojolicious::Controller>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
