package Yancy::Controller::Yancy::API;
our $VERSION = '1.023';
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
#pod Each returned item will be filtered by filters conforming with
#pod L<Mojolicious::Plugin::Yancy/yancy.filter.add> that are passed in the
#pod array-ref in stash key C<filters_out>.
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

    my $coll = $c->stash( 'collection' );
    my $res = $c->yancy->backend->list( $coll, \%filter, \%opt );
    _delete_null_values( @{ $res->{items} } );
    $res->{items} = [
        map _apply_op_filters( $coll, $_, $c->stash( 'filters_out' ), $c->yancy->filters ), @{ $res->{items} }
    ] if $c->stash( 'filters_out' );

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
#pod C<newItem>, and must be a hash/JSON "object". It will be filtered by
#pod filters conforming with L<Mojolicious::Plugin::Yancy/yancy.filter.add>
#pod that are passed in the array-ref in stash key C<filters>, after the
#pod collection and property filters have been applied.
#pod
#pod The return value is filtered like each result is in L</list_items>.
#pod
#pod =cut

sub add_item {
    my ( $c ) = @_;
    return unless $c->openapi->valid_input;
    my $coll = $c->stash( 'collection' );
    my $item = $c->yancy->filter->apply( $coll, $c->validation->param( 'newItem' ) );
    $item = _apply_op_filters( $coll, $item, $c->stash( 'filters' ), $c->yancy->filters )
        if $c->stash( 'filters' );
    my $res = $c->yancy->backend->create( $coll, $item );
    $res = _apply_op_filters( $coll, $res, $c->stash( 'filters_out' ), $c->yancy->filters )
        if $c->stash( 'filters_out' );
    return $c->render(
        status => 201,
        openapi => $res,
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
#pod The return value is filtered like each result is in L</list_items>.
#pod
#pod =cut

sub get_item {
    my ( $c ) = @_;
    return unless $c->openapi->valid_input;
    my $args = $c->validation->output;
    my $id = $args->{ $c->stash( 'id_field' ) };
    my $coll = $c->stash( 'collection' );
    my $res = _delete_null_values( $c->yancy->backend->get( $coll, $id ) );
    $res = _apply_op_filters( $coll, $res, $c->stash( 'filters_out' ), $c->yancy->filters )
        if $c->stash( 'filters_out' );
    return $c->render(
        status => 200,
        openapi => $res,
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
#pod The return value is filtered like each result is in L</list_items>.
#pod
#pod =cut

sub set_item {
    my ( $c ) = @_;
    return unless $c->openapi->valid_input;
    my $args = $c->validation->output;
    my $id = $args->{ $c->stash( 'id_field' ) };
    my $coll = $c->stash( 'collection' );
    my $item = $c->yancy->filter->apply( $coll, $args->{ newItem } );
    $item = _apply_op_filters( $coll, $item, $c->stash( 'filters' ), $c->yancy->filters )
        if $c->stash( 'filters' );
    $c->yancy->backend->set( $coll, $id, $item );

    # ID field may have changed
    $id = $item->{ $c->stash( 'id_field' ) } || $id;

    my $res = _delete_null_values( $c->yancy->backend->get( $coll, $id ) );
    $res = _apply_op_filters( $coll, $res, $c->stash( 'filters_out' ), $c->yancy->filters )
        if $c->stash( 'filters_out' );
    return $c->render(
        status => 200,
        openapi => $res,
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
        delete $item->{ $_ } for grep !defined $item->{ $_ }, keys %$item;
    }
    return wantarray ? @_ : $_[0];
}

#=sub _apply_op_filters
#
# Similar to the helper 'yancy.filter.apply' - filters input item,
# returns updated version.
sub _apply_op_filters {
    my ( $coll, $item, $filters, $app_filters ) = @_;
    $item = { %$item }; # no mutate input
    for my $filter ( @$filters ) {
        ( $filter, my @params ) = @$filter if ref $filter eq 'ARRAY';
        my $sub = $app_filters->{ $filter };
        die "Unknown filter: $filter" unless $sub;
        $item = $sub->( $coll, $item, {}, @params );
    }
    $item;
}

1;

__END__

=pod

=head1 NAME

Yancy::Controller::Yancy::API - An OpenAPI REST controller for the Yancy editor

=head1 VERSION

version 1.023

=head1 DESCRIPTION

This module contains the routes that L<Yancy> uses to work with the
backend data. This API is used by the Yancy editor.

=head1 METHODS

=head2 list_items

List the items in a collection. The collection name should be in the
stash key C<collection>.

Each returned item will be filtered by filters conforming with
L<Mojolicious::Plugin::Yancy/yancy.filter.add> that are passed in the
array-ref in stash key C<filters_out>.

C<$limit>, C<$offset>, and C<$order_by> may be provided as query parameters.

=head2 add_item

Add a new item to the collection. The collection name should be in the
stash key C<collection>.

The new item is extracted from the OpenAPI input, under parameter name
C<newItem>, and must be a hash/JSON "object". It will be filtered by
filters conforming with L<Mojolicious::Plugin::Yancy/yancy.filter.add>
that are passed in the array-ref in stash key C<filters>, after the
collection and property filters have been applied.

The return value is filtered like each result is in L</list_items>.

=head2 get_item

Get a single item from a collection. The collection should be in the
stash key C<collection>.

The item's ID field-name is in the stash key C<id_field>. The ID itself
is extracted from the OpenAPI input, under a parameter of that name.

The return value is filtered like each result is in L</list_items>.

=head2 set_item

Update an item in a collection. The collection should be in the stash
key C<collection>.

The item to be updated is determined as with L</get_item>, and what to
update it with is determined as with L</add_item>.

The return value is filtered like each result is in L</list_items>.

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
