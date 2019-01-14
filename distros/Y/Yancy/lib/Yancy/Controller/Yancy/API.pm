package Yancy::Controller::Yancy::API;
our $VERSION = '1.022';
# ABSTRACT: An OpenAPI REST controller for the Yancy editor

#pod =head1 DESCRIPTION
#pod
#pod This module contains the routes that L<Yancy> uses to work with the
#pod backend data. This API is used by the Yancy editor.
#pod
#pod =head1 SUBCLASSING
#pod
#pod To change how the API provides access to the data in your database, you
#pod can create a custom controller. To do so, you should extend this class
#pod and override the desired methods to provide the desired functionality.
#pod
#pod     package MyApp::Controller::CustomYancyAPI;
#pod     use Mojo::Base 'Yancy::Controller::Yancy::API';
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
#pod         api_controller => 'CustomYancyAPI',
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
#pod stash key C<collection>.
#pod
#pod C<$limit>, C<$offset>, and C<$order_by> may be provided as query parameters.
#pod
#pod =cut

sub list_items {
    my ( $c ) = @_;
    return unless $c->openapi->valid_input;
    my $args = $c->validation->output;

    my %opt = (
        limit => delete $args->{'$limit'},
        offset => delete $args->{'$offset'},
    );
    if ( my $order_by = delete $args->{'$order_by'} ) {
        $opt{order_by} = [
            map +{ "-$_->[0]" => $_->[1] },
            map +[ split /:/ ],
            split /,/, $order_by
        ];
    }

    my %filter;
    for my $key ( keys %$args ) {
        my $value = $args->{ $key };
        if ( ( $value =~ tr/*/%/ ) <= 0 ) {
            $value = "\%$value\%";
        }
        $filter{ $key } = { -like => $value };
    }

    my $res = $c->yancy->backend->list( $c->stash( 'collection' ), \%filter, \%opt );
    _delete_null_values( @{ $res->{items} } );

    return $c->render(
        status => 200,
        openapi => $res,
    );
}

#pod =method add_item
#pod
#pod Add a new item to the collection. The collection name should be in the
#pod stash key C<collection>.
#pod
#pod The new item is extracted from the OpenAPI input, under parameter name
#pod C<newItem>, and must be a hash/JSON "object".
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
#pod stash key C<collection>.
#pod
#pod The item's ID field-name is in the stash key C<id_field>. The ID itself
#pod is extracted from the OpenAPI input, under a parameter of that name.
#pod
#pod =cut

sub get_item {
    my ( $c ) = @_;
    return unless $c->openapi->valid_input;
    my $args = $c->validation->output;
    my $id = $args->{ $c->stash( 'id_field' ) };
    return $c->render(
        status => 200,
        openapi => _delete_null_values( $c->yancy->backend->get( $c->stash( 'collection' ), $id ) ),
    );
}

#pod =method set_item
#pod
#pod Update an item in a collection. The collection should be in the stash
#pod key C<collection>.
#pod
#pod The item to be updated is determined as with L</get_item>, and what to
#pod update it with is determined as with L</add_item>.
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

    # ID field may have changed
    $id = $item->{ $c->stash( 'id_field' ) } || $id;

    return $c->render(
        status => 200,
        openapi => _delete_null_values( $c->yancy->backend->get( $coll, $id ) ),
    );
}

#pod =method delete_item
#pod
#pod Delete an item from a collection. The collection name should be in the
#pod stash key C<collection>.
#pod
#pod The item to be deleted is determined as with L</get_item>.
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

#=sub _delete_null_values
#
#   _delete_null_values( @items );
#
# Remove all the keys with a value of C<undef> from the given items.
# This prevents the user from having to explicitly declare fields that
# can be C<null> as C<< [ 'string', 'null' ] >>. Since this validation
# really only happens when a response is generated, it can be very
# confusing to understand what the problem is
sub _delete_null_values {
    for my $item ( @_ ) {
        for my $key ( grep { !defined $item->{ $_ } } keys %$item ) {
            delete $item->{ $key };
        }
    }
    return @_;
}

1;

__END__

=pod

=head1 NAME

Yancy::Controller::Yancy::API - An OpenAPI REST controller for the Yancy editor

=head1 VERSION

version 1.022

=head1 DESCRIPTION

This module contains the routes that L<Yancy> uses to work with the
backend data. This API is used by the Yancy editor.

=head1 METHODS

=head2 list_items

List the items in a collection. The collection name should be in the
stash key C<collection>.

C<$limit>, C<$offset>, and C<$order_by> may be provided as query parameters.

=head2 add_item

Add a new item to the collection. The collection name should be in the
stash key C<collection>.

The new item is extracted from the OpenAPI input, under parameter name
C<newItem>, and must be a hash/JSON "object".

=head2 get_item

Get a single item from a collection. The collection should be in the
stash key C<collection>.

The item's ID field-name is in the stash key C<id_field>. The ID itself
is extracted from the OpenAPI input, under a parameter of that name.

=head2 set_item

Update an item in a collection. The collection should be in the stash
key C<collection>.

The item to be updated is determined as with L</get_item>, and what to
update it with is determined as with L</add_item>.

=head2 delete_item

Delete an item from a collection. The collection name should be in the
stash key C<collection>.

The item to be deleted is determined as with L</get_item>.

=head1 SUBCLASSING

To change how the API provides access to the data in your database, you
can create a custom controller. To do so, you should extend this class
and override the desired methods to provide the desired functionality.

    package MyApp::Controller::CustomYancyAPI;
    use Mojo::Base 'Yancy::Controller::Yancy::API';
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
        api_controller => 'CustomYancyAPI',
    };

For an example, you could extend this class to add authorization based
on your own requirements.

=head1 SEE ALSO

L<Yancy>, L<Mojolicious::Controller>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
