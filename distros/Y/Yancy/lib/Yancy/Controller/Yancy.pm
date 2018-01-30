package Yancy::Controller::Yancy;
our $VERSION = '0.012';
# ABSTRACT: A simple REST controller for Mojolicious

#pod =head1 DESCRIPTION
#pod
#pod This module contains the routes that L<Yancy> uses to work with the
#pod backend data. This API is used by the web application.
#pod
#pod =head1 SUBCLASSING
#pod
#pod To change how the API provides access to the data in your database, you
#pod can create a custom controller. To do so, you should extend this class
#pod and override the desired methods to provide the desired functionality.
#pod
#pod     package MyApp::Controller::CustomYancy;
#pod     use Mojo::Base 'Yancy::Controller::Yancy';
#pod     sub list_items {
#pod         my ( $c ) = @_;
#pod         return unless $c->openapi->valid_input;
#pod         my $items = $c->yancy->backend->list( $c->stash( 'collection' ) );
#pod         return $c->render(
#pod             status => 200,
#pod             openapi => $items,
#pod         );
#pod     }
#pod
#pod     package main;
#pod     use Mojolicious::Lite;
#pod     push @{ app->routes->namespaces }, 'MyApp::Controller';
#pod     plugin Yancy => {
#pod         controller_class => 'CustomYancy',
#pod     };
#pod
#pod For an example, you could extend this class to add authorization based
#pod on your own requirements.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Yancy>, L<Mojolicious::Controller>
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Controller';

#pod =method list_items
#pod
#pod List the items in a collection. The collection name should be in the
#pod stash key C<collection>. C<limit>, C<offset>, and C<order_by> may be
#pod provided as query parameters.
#pod
#pod =cut

sub list_items {
    my ( $c ) = @_;
    return unless $c->openapi->valid_input;
    my $args = $c->validation->output;
    my %opt = (
        limit => $args->{limit},
        offset => $args->{offset},
    );
    if ( $args->{order_by} ) {
        $opt{order_by} = [
            map +{ "-$_->[0]" => $_->[1] },
            map +[ split /:/ ],
            split /,/, $args->{order_by}
        ];
    }
    return $c->render(
        status => 200,
        openapi => $c->yancy->backend->list( $c->stash( 'collection' ), {}, \%opt ),
    );
}

#pod =method add_item
#pod
#pod Add a new item to the collection. The new item should be in the request
#pod body as JSON. The collection name should be in the stash key C<collection>.
#pod
#pod =cut

sub add_item {
    my ( $c ) = @_;
    return unless $c->openapi->valid_input;
    my $coll = $c->stash( 'collection' );
    my $item = $c->yancy->filter->apply( $coll, $c->validation->param( 'newItem' ) );
    return $c->render(
        status => 201,
        openapi => $c->yancy->backend->create( $coll, $item ),
    );
}

#pod =method get_item
#pod
#pod Get a single item from a collection. The collection should be in the
#pod stash key C<collection>, and the item's ID in the stash key C<id>.
#pod
#pod =cut

sub get_item {
    my ( $c ) = @_;
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

sub set_item {
    my ( $c ) = @_;
    return unless $c->openapi->valid_input;
    my $args = $c->validation->output;
    my $id = $args->{ $c->stash( 'id_field' ) };
    my $coll = $c->stash( 'collection' );
    my $item = $c->yancy->filter->apply( $coll, $args->{ newItem } );
    $c->yancy->backend->set( $coll, $id, $item );
    return $c->render(
        status => 200,
        openapi => $c->yancy->backend->get( $coll, $id ),
    );
}

#pod =method delete_item
#pod
#pod Delete an item from a collection. The collection name should be in the
#pod stash key C<collection>. The ID of the item should be in the stash key
#pod C<id>.
#pod
#pod =cut

sub delete_item {
    my ( $c ) = @_;
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

version 0.012

=head1 DESCRIPTION

This module contains the routes that L<Yancy> uses to work with the
backend data. This API is used by the web application.

=head1 METHODS

=head2 list_items

List the items in a collection. The collection name should be in the
stash key C<collection>. C<limit>, C<offset>, and C<order_by> may be
provided as query parameters.

=head2 add_item

Add a new item to the collection. The new item should be in the request
body as JSON. The collection name should be in the stash key C<collection>.

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

=head1 SUBCLASSING

To change how the API provides access to the data in your database, you
can create a custom controller. To do so, you should extend this class
and override the desired methods to provide the desired functionality.

    package MyApp::Controller::CustomYancy;
    use Mojo::Base 'Yancy::Controller::Yancy';
    sub list_items {
        my ( $c ) = @_;
        return unless $c->openapi->valid_input;
        my $items = $c->yancy->backend->list( $c->stash( 'collection' ) );
        return $c->render(
            status => 200,
            openapi => $items,
        );
    }

    package main;
    use Mojolicious::Lite;
    push @{ app->routes->namespaces }, 'MyApp::Controller';
    plugin Yancy => {
        controller_class => 'CustomYancy',
    };

For an example, you could extend this class to add authorization based
on your own requirements.

=head1 SEE ALSO

L<Yancy>, L<Mojolicious::Controller>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
