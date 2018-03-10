package Yancy::Controller::Yancy::MultiTenant;
our $VERSION = '0.022';
# ABSTRACT: A controller to show a user only their content

#pod =head1 DESCRIPTION
#pod
#pod This module contains routes to manage content owned by users. Each user
#pod is allowed to see and manage only their own content.
#pod
#pod =head1 CONFIGURATION
#pod
#pod To use this controller, you must add some additional configuration to
#pod your collections. This configuration will map collection fields to
#pod Mojolicious stash values. You must then set these stash values on every
#pod request so that users are restricted to their own content.
#pod
#pod     use Mojolicious::Lite;
#pod     plugin Yancy => {
#pod         controller_class => 'Yancy::MultiTenant',
#pod         collections => {
#pod             blog => {
#pod                 # Map collection fields to stash values
#pod                 'x-stash-fields' => {
#pod                     # collection field => stash field
#pod                     user_id => 'current_user_id',
#pod                 },
#pod                 properties => {
#pod                     id => { type => 'integer', readOnly => 1 },
#pod                     user_id => { type => 'integer', readOnly => 1 },
#pod                     title => { type => 'string' },
#pod                     content => { type => 'string' },
#pod                 },
#pod             },
#pod         },
#pod     };
#pod
#pod     under '/' => sub {
#pod         my ( $c ) = @_;
#pod         # Pull out the current user's username from the session.
#pod         # See Yancy::Plugin::Auth::Basic for a way to set the username
#pod         $c->stash( current_user_id => $c->session( 'username' ) );
#pod     };
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Yancy::Controller::Yancy>, L<Mojolicious::Controller>
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Controller';

sub _build_tenant_filter {
    my ( $c, $coll ) = @_;
    my $filter = $c->yancy->config->{collections}{$coll}{'x-stash-filter'} || {};
    #; use Data::Dumper; say "Filter: " . Dumper $filter;
    my %query = (
        map {; $_ => $c->stash( $filter->{ $_ } ) }
        keys %$filter
    );
    #; use Data::Dumper; say "Query: " . Dumper \%query;
    return %query;
}

sub _fetch_authorized_item {
    my ( $c, $coll, $id ) = @_;
    my $item = $c->yancy->backend->get( $coll, $id );
    my %filter = $c->_build_tenant_filter( $coll );
    if ( grep { $item->{ $_ } ne $filter{ $_ } } keys %filter ) {
        return;
    }
    return $item;
}

#pod =method list_items
#pod
#pod List the items in a collection. A user only can see items owned by
#pod themselves.
#pod
#pod =cut

sub list_items {
    my ( $c ) = @_;
    return unless $c->openapi->valid_input;
    my %query = $c->_build_tenant_filter( $c->stash( 'collection' ) );
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
        openapi => $c->yancy->backend->list( $c->stash( 'collection' ), \%query, \%opt ),
    );
}

#pod =method add_item
#pod
#pod Add a new item to the collection. This new item will be owned by the
#pod current user.
#pod
#pod =cut

sub add_item {
    my ( $c ) = @_;
    return unless $c->openapi->valid_input;
    my $coll = $c->stash( 'collection' );
    my $item = {
        %{ $c->yancy->filter->apply( $coll, $c->validation->param( 'newItem' ) ) },
        $c->_build_tenant_filter( $coll ),
    };
    return $c->render(
        status => 201,
        openapi => $c->yancy->backend->create( $coll, $item ),
    );
}

#pod =method get_item
#pod
#pod Get a single item from a collection. Users can only view items owned
#pod by them.
#pod
#pod =cut

sub get_item {
    my ( $c ) = @_;
    return unless $c->openapi->valid_input;
    my $args = $c->validation->output;
    my $id = $args->{ $c->stash( 'id_field' ) };
    my $item = $c->_fetch_authorized_item( $c->stash( 'collection' ), $id );
    if ( !$item ) {
        return $c->render(
            status => 401,
            openapi => {
                message => 'Unauthorized',
            },
        );
    }
    return $c->render(
        status => 200,
        openapi => $item,
    );
}

#pod =method set_item
#pod
#pod Update an item in a collection. Users can only update items that they
#pod own.
#pod
#pod =cut

sub set_item {
    my ( $c ) = @_;
    return unless $c->openapi->valid_input;
    my $args = $c->validation->output;
    my $id = $args->{ $c->stash( 'id_field' ) };
    my $coll = $c->stash( 'collection' );
    if ( $c->_fetch_authorized_item( $coll, $id ) ) {
        my $new_item = {
            %{ $c->yancy->filter->apply( $coll, $args->{ newItem } ) },
            $c->_build_tenant_filter( $coll ),
        };
        $c->yancy->backend->set( $coll, $id, $new_item );
        return $c->render(
            status => 200,
            openapi => $c->yancy->backend->get( $coll, $id ),
        );
    }
    return $c->render(
        status => 401,
        openapi => {
            message => 'Unauthorized',
        },
    );
}

#pod =method delete_item
#pod
#pod Delete an item from a collection. Users can only delete items they own.
#pod
#pod =cut

sub delete_item {
    my ( $c ) = @_;
    return unless $c->openapi->valid_input;
    my $args = $c->validation->output;
    my $id = $args->{ $c->stash( 'id_field' ) };
    if ( $c->_fetch_authorized_item( $c->stash( 'collection' ), $id ) ) {
        $c->yancy->backend->delete( $c->stash( 'collection' ), $id );
        return $c->rendered( 204 );
    }
    return $c->render(
        status => 401,
        openapi => {
            message => 'Unauthorized',
        },
    );
}

1;

__END__

=pod

=head1 NAME

Yancy::Controller::Yancy::MultiTenant - A controller to show a user only their content

=head1 VERSION

version 0.022

=head1 DESCRIPTION

This module contains routes to manage content owned by users. Each user
is allowed to see and manage only their own content.

=head1 METHODS

=head2 list_items

List the items in a collection. A user only can see items owned by
themselves.

=head2 add_item

Add a new item to the collection. This new item will be owned by the
current user.

=head2 get_item

Get a single item from a collection. Users can only view items owned
by them.

=head2 set_item

Update an item in a collection. Users can only update items that they
own.

=head2 delete_item

Delete an item from a collection. Users can only delete items they own.

=head1 CONFIGURATION

To use this controller, you must add some additional configuration to
your collections. This configuration will map collection fields to
Mojolicious stash values. You must then set these stash values on every
request so that users are restricted to their own content.

    use Mojolicious::Lite;
    plugin Yancy => {
        controller_class => 'Yancy::MultiTenant',
        collections => {
            blog => {
                # Map collection fields to stash values
                'x-stash-fields' => {
                    # collection field => stash field
                    user_id => 'current_user_id',
                },
                properties => {
                    id => { type => 'integer', readOnly => 1 },
                    user_id => { type => 'integer', readOnly => 1 },
                    title => { type => 'string' },
                    content => { type => 'string' },
                },
            },
        },
    };

    under '/' => sub {
        my ( $c ) = @_;
        # Pull out the current user's username from the session.
        # See Yancy::Plugin::Auth::Basic for a way to set the username
        $c->stash( current_user_id => $c->session( 'username' ) );
    };

=head1 SEE ALSO

L<Yancy::Controller::Yancy>, L<Mojolicious::Controller>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
