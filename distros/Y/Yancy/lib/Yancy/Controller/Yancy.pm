package Yancy::Controller::Yancy;
our $VERSION = '1.022';
# ABSTRACT: Basic controller for displaying content

#pod =head1 SYNOPSIS
#pod
#pod     use Mojolicious::Lite;
#pod     plugin Yancy => {
#pod         collections => {
#pod             blog => {
#pod                 properties => {
#pod                     id => { type => 'integer' },
#pod                     title => { type => 'string' },
#pod                     html => { type => 'string' },
#pod                 },
#pod             },
#pod         },
#pod     };
#pod
#pod     app->routes->get( '/' )->to(
#pod         'yancy#list',
#pod         collection => 'blog',
#pod         template => 'index',
#pod     );
#pod
#pod     __DATA__
#pod     @@ index.html.ep
#pod     % for my $item ( @{ stash 'items' } ) {
#pod         <h1><%= $item->{title} %></h1>
#pod         <%== $item->{html} %>
#pod     % }
#pod
#pod =head1 DESCRIPTION
#pod
#pod This controller contains basic route handlers for displaying content
#pod configured in Yancy collections. These route handlers reduce the amount
#pod of code you need to write to display or modify your content.
#pod
#pod Route handlers use the Mojolicious C<stash> for configuration. These values
#pod can be set at route creation, or by an C<under> route handler.
#pod
#pod Using these route handlers also gives you a built-in JSON API for your
#pod website. Any user agent that requests JSON will get JSON instead of
#pod HTML. For full details on how JSON clients are detected, see
#pod L<Mojolicious::Guides::Rendering/Content negotiation>.
#pod
#pod =head1 EXTENDING
#pod
#pod Here are some tips for inheriting from this controller to add
#pod functionality.
#pod
#pod =over
#pod
#pod =item set
#pod
#pod =over
#pod
#pod =item *
#pod
#pod When setting field values to add to the updated/created item, use C<<
#pod $c->req->param >> not C<< $c->param >>. The underlying code uses C<<
#pod $c->req->param >> to get all of the params, which will not be updated if
#pod you use C<< $c->param >>.
#pod
#pod =back
#pod
#pod =back
#pod
#pod =head1 DIAGNOSTICS
#pod
#pod =over
#pod
#pod =item Page not found
#pod
#pod If you get a C<404 Not Found> response or Mojolicious's "Page not found... yet!" page,
#pod it could be from one of a few reasons:
#pod
#pod =over
#pod
#pod =item No route with the given path was found
#pod
#pod Check to make sure that your routes match the URL.
#pod
#pod =item Configured template not found
#pod
#pod Make sure the template is configured and named correctly and the correct format
#pod and renderer are being used.
#pod
#pod =back
#pod
#pod The Mojolicious debug log will have more information. Make sure you are
#pod logging at C<debug> level by running in C<development> mode (the
#pod default), or setting the C<MOJO_LOG_LEVEL> environment variable to
#pod C<debug>. See L<MODE in the Mojolicious
#pod tutorial|Mojolicious::Guides::Tutorial/Mode> for more information.
#pod
#pod =back
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Yancy>
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Controller';

#pod =method list
#pod
#pod     $routes->get( '/' )->to(
#pod         'yancy#list',
#pod         collection => $collection_name,
#pod         template => $template_name,
#pod     );
#pod
#pod This method is used to list content.
#pod
#pod This method uses the following stash values for configuration:
#pod
#pod =over
#pod
#pod =item collection
#pod
#pod The collection to use. Required.
#pod
#pod =item template
#pod
#pod The name of the template to use. See L<Mojolicious::Guides::Rendering/Renderer>
#pod for how template names are resolved.
#pod
#pod =item limit
#pod
#pod The number of items to show on the page. Defaults to C<10>.
#pod
#pod =item page
#pod
#pod The page number to show. Defaults to C<1>. The page number will
#pod be used to calculate the C<offset> parameter to L<Yancy::Backend/list>.
#pod
#pod =item filter
#pod
#pod A hash reference of field/value pairs to filter the contents of the
#pod list.
#pod
#pod =back
#pod
#pod The following stash values are set by this method:
#pod
#pod =over
#pod
#pod =item items
#pod
#pod An array reference of items to display.
#pod
#pod =item total_pages
#pod
#pod The number of pages of items. Can be used for pagination.
#pod
#pod =back
#pod
#pod =cut

sub list {
    my ( $c ) = @_;
    my $coll_name = $c->stash( 'collection' )
        || die "Collection name not defined in stash";
    my $limit = $c->stash->{ limit } //= 10;
    my $page = $c->stash->{ page } //= 1;
    my $offset = ( $page - 1 ) * $limit;
    my $opt = {
        limit => $limit,
        offset => $offset,
    };
    my $filter = {
        %{ $c->stash( 'filter' ) || {} },
    };
    my $items = $c->yancy->backend->list( $coll_name, $filter, $opt );
    return $c->respond_to(
        json => sub {
            $c->stash( json => { %$items, offset => $offset } );
        },
        html => sub {
            $c->stash(
                %$items,
                total_pages => int( $items->{total} / $limit ) + 1,
            );
        },
    );
}

#pod =method get
#pod
#pod     $routes->get( '/:id' )->to(
#pod         'yancy#get',
#pod         collection => $collection_name,
#pod         template => $template_name,
#pod     );
#pod
#pod This method is used to show a single item.
#pod
#pod This method uses the following stash values for configuration:
#pod
#pod =over
#pod
#pod =item collection
#pod
#pod The collection to use. Required.
#pod
#pod =item id
#pod
#pod The ID of the item from the collection. Required. Usually part of
#pod the route path as a placeholder.
#pod
#pod =item template
#pod
#pod The name of the template to use. See L<Mojolicious::Guides::Rendering/Renderer>
#pod for how template names are resolved.
#pod
#pod =back
#pod
#pod The following stash values are set by this method:
#pod
#pod =over
#pod
#pod =item item
#pod
#pod The item that is being displayed.
#pod
#pod =back
#pod
#pod =cut

sub get {
    my ( $c ) = @_;
    my $coll_name = $c->stash( 'collection' )
        || die "Collection name not defined in stash";
    my $id = $c->stash( 'id' ) // die 'ID not defined in stash';
    my $item = $c->yancy->backend->get( $coll_name => $id );
    if ( !$item ) {
        $c->reply->not_found;
        return;
    }
    return $c->respond_to(
        json => sub { $c->stash( json => $item ) },
        html => sub { $c->stash( item => $item ) },
    );
}

#pod =method set
#pod
#pod     $routes->any( [ 'GET', 'POST' ] => '/:id/edit' )->to(
#pod         'yancy#set',
#pod         collection => $collection_name,
#pod         template => $template_name,
#pod     );
#pod
#pod     $routes->any( [ 'GET', 'POST' ] => '/create' )->to(
#pod         'yancy#set',
#pod         collection => $collection_name,
#pod         template => $template_name,
#pod         forward_to => $route_name,
#pod     );
#pod
#pod This route creates a new item or updates an existing item in
#pod a collection. If the user is making a C<GET> request, they will simply
#pod be shown the template. If the user is making a C<POST> or C<PUT>
#pod request, the form parameters will be read, the data will be validated
#pod against L<the collection configuration|Yancy::Help::Config/Data
#pod Collections>, and the user will either be shown the form again with the
#pod result of the form submission (success or failure) or the user will be
#pod forwarded to another place.
#pod
#pod This method uses the following stash values for configuration:
#pod
#pod =over
#pod
#pod =item collection
#pod
#pod The collection to use. Required.
#pod
#pod =item id
#pod
#pod The ID of the item from the collection. Optional: If not specified, a new
#pod item will be created. Usually part of the route path as a placeholder.
#pod
#pod =item template
#pod
#pod The name of the template to use. See L<Mojolicious::Guides::Rendering/Renderer>
#pod for how template names are resolved.
#pod
#pod =item forward_to
#pod
#pod The name of a route to forward the user to on success. Optional. Any
#pod route placeholders that match item field names will be filled in.
#pod
#pod     $routes->get( '/:id/:slug' )->name( 'blog.view' );
#pod     $routes->post( '/create' )->to(
#pod         'yancy#set',
#pod         collection => 'blog',
#pod         template => 'blog_edit.html.ep',
#pod         forward_to => 'blog.view',
#pod     );
#pod
#pod     # { id => 1, slug => 'first-post' }
#pod     # forward_to => '/1/first-post'
#pod
#pod Forwarding will not happen for JSON requests.
#pod
#pod =item properties
#pod
#pod Restrict this route to only setting the given properties. An array
#pod reference of properties to allow. Trying to set additional properties
#pod will result in an error.
#pod
#pod B<NOTE:> Unless restricted to certain properties using this
#pod configuration, this method accepts all valid data configured for the
#pod collection. The data being submitted can be more than just the fields
#pod you make available in the form. If you do not want certain data to be
#pod written through this form, you can prevent it by using this.
#pod
#pod =back
#pod
#pod The following stash values are set by this method:
#pod
#pod =over
#pod
#pod =item item
#pod
#pod The item that is being edited, if the C<id> is given. Otherwise, the
#pod item that was created.
#pod
#pod =item errors
#pod
#pod An array of hash references of errors that occurred during data
#pod validation. Each hash reference is either a L<JSON::Validator::Error>
#pod object or a hash reference with a C<message> field. See L<the
#pod yancy.validate helper docs|Mojolicious::Plugin::Yancy/yancy.validate>
#pod and L<JSON::Validator/validate> for more details.
#pod
#pod =back
#pod
#pod Each field in the item is also set as a param using
#pod L<Mojolicious::Controller/param> so that tag helpers like C<text_field>
#pod will be pre-filled with the values. See
#pod L<Mojolicious::Plugin::TagHelpers> for more information. This also means
#pod that fields can be pre-filled with initial data or new data by using GET
#pod query parameters.
#pod
#pod This method is protected by L<Mojolicious's Cross-Site Request Forgery
#pod (CSRF) protection|Mojolicious::Guides::Rendering/Cross-site request
#pod forgery>. CSRF protection prevents other sites from tricking your users
#pod into doing something on your site that they didn't intend, such as
#pod editing or deleting content. You must add a C<< <%= csrf_field %> >> to
#pod your form in order to delete an item successfully. See
#pod L<Mojolicious::Guides::Rendering/Cross-site request forgery>.
#pod
#pod Displaying a form could be done as a separate route using the C<yancy#get>
#pod method, but with more code:
#pod
#pod     $routes->get( '/:id/edit' )->to(
#pod         'yancy#get',
#pod         collection => $collection_name,
#pod         template => $template_name,
#pod     );
#pod     $routes->post( '/:id/edit' )->to(
#pod         'yancy#set',
#pod         collection => $collection_name,
#pod         template => $template_name,
#pod     );
#pod
#pod =cut

sub set {
    my ( $c ) = @_;
    my $coll_name = $c->stash( 'collection' )
        || die "Collection name not defined in stash";
    my $id = $c->stash( 'id' );

    # Display the form, if requested. This makes the simple case of
    # displaying and managing a form easier with a single route instead
    # of two routes (one to "yancy#get" and one to "yancy#set")
    if ( $c->req->method eq 'GET' ) {
        if ( $id ) {
            my $item = $c->yancy->get( $coll_name => $id );
            $c->stash( item => $item );
            my $props = $c->yancy->schema( $coll_name )->{properties};
            for my $key ( keys %$props ) {
                # Mojolicious TagHelpers take current values through the
                # params, but also we allow pre-filling values through the
                # GET query parameters (except for passwords)
                next if $props->{ $key }{ format }
                    && $props->{ $key }{ format } eq 'password';
                $c->param( $key => $c->param( $key ) // $item->{ $key } );
            }
        }

        $c->respond_to(
            json => {
                status => 400,
                json => {
                    errors => [
                        {
                            message => 'GET request for JSON invalid',
                        },
                    ],
                },
            },
            html => { },
        );
        return;
    }

    if ( $c->accepts( 'html' ) && $c->validation->csrf_protect->has_error( 'csrf_token' ) ) {
        $c->app->log->error( 'CSRF token validation failed' );
        $c->render(
            status => 400,
            item => $c->yancy->get( $coll_name => $id ),
            errors => [
                {
                    message => 'CSRF token invalid.',
                },
            ],
        );
        return;
    }

    my $data = $c->req->params->to_hash;
    delete $data->{csrf_token};
    #; use Data::Dumper;
    #; $c->app->log->debug( Dumper $data );

    my $props = $c->yancy->schema( $coll_name )->{properties};
    for my $key ( keys %$props ) {
        my $format = $props->{ $key }{ format };
        # Password cannot be changed to an empty string
        if ( $format && $format eq 'password' ) {
            if ( exists $data->{ $key } &&
                ( !defined $data->{ $key } || $data->{ $key } eq '' )
            ) {
                delete $data->{ $key };
            }
        }
    }

    my %opt;
    if ( my $props = $c->stash( 'properties' ) ) {
        $opt{ properties } = $props;
    }

    my $update = $id ? 1 : 0;
    if ( $update ) {
        eval { $c->yancy->set( $coll_name, $id, $data, %opt ) };
    }
    else {
        $id = eval { $c->yancy->create( $coll_name, $data ) };
    }

    if ( my $errors = $@ ) {
        if ( ref $errors eq 'ARRAY' ) {
            # Validation error
            $c->res->code( 400 );
        }
        else {
            # Unknown error
            $c->res->code( 500 );
            $errors = [ { message => $errors } ];
        }
        my $item = $c->yancy->get( $coll_name, $id );
        $c->respond_to(
            json => { json => { errors => $errors } },
            html => { item => $item, errors => $errors },
        );
        return;
    }

    my $item = $c->yancy->get( $coll_name, $id );
    return $c->respond_to(
        json => sub {
            $c->stash(
                status => $update ? 200 : 201,
                json => $item,
            );
        },
        html => sub {
            if ( my $route = $c->stash( 'forward_to' ) ) {
                $c->redirect_to( $route, %$item );
                return;
            }
            $c->stash( item => $item );
        },
    );
}

#pod =method delete
#pod
#pod     $routes->any( [ 'GET', 'POST' ], '/delete/:id' )->to(
#pod         'yancy#delete',
#pod         collection => $collection_name,
#pod         template => $template_name,
#pod         forward_to => $route_name,
#pod     );
#pod
#pod This route deletes an item from a collection. If the user is making
#pod a C<GET> request, they will simply be shown the template (which can be
#pod used to confirm the delete). If the user is making a C<POST> or C<DELETE>
#pod request, the item will be deleted and the user will either be shown the
#pod form again with the result of the form submission (success or failure)
#pod or the user will be forwarded to another place.
#pod
#pod This method uses the following stash values for configuration:
#pod
#pod =over
#pod
#pod =item collection
#pod
#pod The collection to use. Required.
#pod
#pod =item id
#pod
#pod The ID of the item from the collection. Required. Usually part of the
#pod route path as a placeholder.
#pod
#pod =item template
#pod
#pod The name of the template to use. See L<Mojolicious::Guides::Rendering/Renderer>
#pod for how template names are resolved.
#pod
#pod =item forward_to
#pod
#pod The name of a route to forward the user to on success. Optional.
#pod Forwarding will not happen for JSON requests.
#pod
#pod =back
#pod
#pod The following stash values are set by this method:
#pod
#pod =over
#pod
#pod =item item
#pod
#pod The item that will be deleted. If displaying the form again after the item is deleted,
#pod this will be C<undef>.
#pod
#pod =back
#pod
#pod This method is protected by L<Mojolicious's Cross-Site Request Forgery
#pod (CSRF) protection|Mojolicious::Guides::Rendering/Cross-site request
#pod forgery>.  CSRF protection prevents other sites from tricking your users
#pod into doing something on your site that they didn't intend, such as
#pod editing or deleting content.  You must add a C<< <%= csrf_field %> >> to
#pod your form in order to delete an item successfully. See
#pod L<Mojolicious::Guides::Rendering/Cross-site request forgery>.
#pod
#pod =cut

sub delete {
    my ( $c ) = @_;
    my $coll_name = $c->stash( 'collection' )
        || die "Collection name not defined in stash";
    my $id = $c->stash( 'id' ) // die 'ID not defined in stash';

    # Display the form, if requested. This makes it easy to display
    # a confirmation page in a single route.
    if ( $c->req->method eq 'GET' ) {
        my $item = $c->yancy->get( $coll_name => $id );
        $c->respond_to(
            json => {
                status => 400,
                json => {
                    errors => [
                        {
                            message => 'GET request for JSON invalid',
                        },
                    ],
                },
            },
            html => { item => $item },
        );
        return;
    }

    if ( $c->accepts( 'html' ) && $c->validation->csrf_protect->has_error( 'csrf_token' ) ) {
        $c->app->log->error( 'CSRF token validation failed' );
        $c->render(
            status => 400,
            item => $c->yancy->get( $coll_name => $id ),
            errors => [
                {
                    message => 'CSRF token invalid.',
                },
            ],
        );
        return;
    }

    $c->yancy->delete( $coll_name, $id );

    return $c->respond_to(
        json => sub {
            $c->rendered( 204 );
            return;
        },
        html => sub {
            if ( my $route = $c->stash( 'forward_to' ) ) {
                $c->redirect_to( $route );
                return;
            }
        },
    );
}

1;

__END__

=pod

=head1 NAME

Yancy::Controller::Yancy - Basic controller for displaying content

=head1 VERSION

version 1.022

=head1 SYNOPSIS

    use Mojolicious::Lite;
    plugin Yancy => {
        collections => {
            blog => {
                properties => {
                    id => { type => 'integer' },
                    title => { type => 'string' },
                    html => { type => 'string' },
                },
            },
        },
    };

    app->routes->get( '/' )->to(
        'yancy#list',
        collection => 'blog',
        template => 'index',
    );

    __DATA__
    @@ index.html.ep
    % for my $item ( @{ stash 'items' } ) {
        <h1><%= $item->{title} %></h1>
        <%== $item->{html} %>
    % }

=head1 DESCRIPTION

This controller contains basic route handlers for displaying content
configured in Yancy collections. These route handlers reduce the amount
of code you need to write to display or modify your content.

Route handlers use the Mojolicious C<stash> for configuration. These values
can be set at route creation, or by an C<under> route handler.

Using these route handlers also gives you a built-in JSON API for your
website. Any user agent that requests JSON will get JSON instead of
HTML. For full details on how JSON clients are detected, see
L<Mojolicious::Guides::Rendering/Content negotiation>.

=head1 METHODS

=head2 list

    $routes->get( '/' )->to(
        'yancy#list',
        collection => $collection_name,
        template => $template_name,
    );

This method is used to list content.

This method uses the following stash values for configuration:

=over

=item collection

The collection to use. Required.

=item template

The name of the template to use. See L<Mojolicious::Guides::Rendering/Renderer>
for how template names are resolved.

=item limit

The number of items to show on the page. Defaults to C<10>.

=item page

The page number to show. Defaults to C<1>. The page number will
be used to calculate the C<offset> parameter to L<Yancy::Backend/list>.

=item filter

A hash reference of field/value pairs to filter the contents of the
list.

=back

The following stash values are set by this method:

=over

=item items

An array reference of items to display.

=item total_pages

The number of pages of items. Can be used for pagination.

=back

=head2 get

    $routes->get( '/:id' )->to(
        'yancy#get',
        collection => $collection_name,
        template => $template_name,
    );

This method is used to show a single item.

This method uses the following stash values for configuration:

=over

=item collection

The collection to use. Required.

=item id

The ID of the item from the collection. Required. Usually part of
the route path as a placeholder.

=item template

The name of the template to use. See L<Mojolicious::Guides::Rendering/Renderer>
for how template names are resolved.

=back

The following stash values are set by this method:

=over

=item item

The item that is being displayed.

=back

=head2 set

    $routes->any( [ 'GET', 'POST' ] => '/:id/edit' )->to(
        'yancy#set',
        collection => $collection_name,
        template => $template_name,
    );

    $routes->any( [ 'GET', 'POST' ] => '/create' )->to(
        'yancy#set',
        collection => $collection_name,
        template => $template_name,
        forward_to => $route_name,
    );

This route creates a new item or updates an existing item in
a collection. If the user is making a C<GET> request, they will simply
be shown the template. If the user is making a C<POST> or C<PUT>
request, the form parameters will be read, the data will be validated
against L<the collection configuration|Yancy::Help::Config/Data
Collections>, and the user will either be shown the form again with the
result of the form submission (success or failure) or the user will be
forwarded to another place.

This method uses the following stash values for configuration:

=over

=item collection

The collection to use. Required.

=item id

The ID of the item from the collection. Optional: If not specified, a new
item will be created. Usually part of the route path as a placeholder.

=item template

The name of the template to use. See L<Mojolicious::Guides::Rendering/Renderer>
for how template names are resolved.

=item forward_to

The name of a route to forward the user to on success. Optional. Any
route placeholders that match item field names will be filled in.

    $routes->get( '/:id/:slug' )->name( 'blog.view' );
    $routes->post( '/create' )->to(
        'yancy#set',
        collection => 'blog',
        template => 'blog_edit.html.ep',
        forward_to => 'blog.view',
    );

    # { id => 1, slug => 'first-post' }
    # forward_to => '/1/first-post'

Forwarding will not happen for JSON requests.

=item properties

Restrict this route to only setting the given properties. An array
reference of properties to allow. Trying to set additional properties
will result in an error.

B<NOTE:> Unless restricted to certain properties using this
configuration, this method accepts all valid data configured for the
collection. The data being submitted can be more than just the fields
you make available in the form. If you do not want certain data to be
written through this form, you can prevent it by using this.

=back

The following stash values are set by this method:

=over

=item item

The item that is being edited, if the C<id> is given. Otherwise, the
item that was created.

=item errors

An array of hash references of errors that occurred during data
validation. Each hash reference is either a L<JSON::Validator::Error>
object or a hash reference with a C<message> field. See L<the
yancy.validate helper docs|Mojolicious::Plugin::Yancy/yancy.validate>
and L<JSON::Validator/validate> for more details.

=back

Each field in the item is also set as a param using
L<Mojolicious::Controller/param> so that tag helpers like C<text_field>
will be pre-filled with the values. See
L<Mojolicious::Plugin::TagHelpers> for more information. This also means
that fields can be pre-filled with initial data or new data by using GET
query parameters.

This method is protected by L<Mojolicious's Cross-Site Request Forgery
(CSRF) protection|Mojolicious::Guides::Rendering/Cross-site request
forgery>. CSRF protection prevents other sites from tricking your users
into doing something on your site that they didn't intend, such as
editing or deleting content. You must add a C<< <%= csrf_field %> >> to
your form in order to delete an item successfully. See
L<Mojolicious::Guides::Rendering/Cross-site request forgery>.

Displaying a form could be done as a separate route using the C<yancy#get>
method, but with more code:

    $routes->get( '/:id/edit' )->to(
        'yancy#get',
        collection => $collection_name,
        template => $template_name,
    );
    $routes->post( '/:id/edit' )->to(
        'yancy#set',
        collection => $collection_name,
        template => $template_name,
    );

=head2 delete

    $routes->any( [ 'GET', 'POST' ], '/delete/:id' )->to(
        'yancy#delete',
        collection => $collection_name,
        template => $template_name,
        forward_to => $route_name,
    );

This route deletes an item from a collection. If the user is making
a C<GET> request, they will simply be shown the template (which can be
used to confirm the delete). If the user is making a C<POST> or C<DELETE>
request, the item will be deleted and the user will either be shown the
form again with the result of the form submission (success or failure)
or the user will be forwarded to another place.

This method uses the following stash values for configuration:

=over

=item collection

The collection to use. Required.

=item id

The ID of the item from the collection. Required. Usually part of the
route path as a placeholder.

=item template

The name of the template to use. See L<Mojolicious::Guides::Rendering/Renderer>
for how template names are resolved.

=item forward_to

The name of a route to forward the user to on success. Optional.
Forwarding will not happen for JSON requests.

=back

The following stash values are set by this method:

=over

=item item

The item that will be deleted. If displaying the form again after the item is deleted,
this will be C<undef>.

=back

This method is protected by L<Mojolicious's Cross-Site Request Forgery
(CSRF) protection|Mojolicious::Guides::Rendering/Cross-site request
forgery>.  CSRF protection prevents other sites from tricking your users
into doing something on your site that they didn't intend, such as
editing or deleting content.  You must add a C<< <%= csrf_field %> >> to
your form in order to delete an item successfully. See
L<Mojolicious::Guides::Rendering/Cross-site request forgery>.

=head1 EXTENDING

Here are some tips for inheriting from this controller to add
functionality.

=over

=item set

=over

=item *

When setting field values to add to the updated/created item, use C<<
$c->req->param >> not C<< $c->param >>. The underlying code uses C<<
$c->req->param >> to get all of the params, which will not be updated if
you use C<< $c->param >>.

=back

=back

=head1 DIAGNOSTICS

=over

=item Page not found

If you get a C<404 Not Found> response or Mojolicious's "Page not found... yet!" page,
it could be from one of a few reasons:

=over

=item No route with the given path was found

Check to make sure that your routes match the URL.

=item Configured template not found

Make sure the template is configured and named correctly and the correct format
and renderer are being used.

=back

The Mojolicious debug log will have more information. Make sure you are
logging at C<debug> level by running in C<development> mode (the
default), or setting the C<MOJO_LOG_LEVEL> environment variable to
C<debug>. See L<MODE in the Mojolicious
tutorial|Mojolicious::Guides::Tutorial/Mode> for more information.

=back

=head1 SEE ALSO

L<Yancy>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
