package Yancy::Plugin::Auth::Basic;
our $VERSION = '1.014';
# ABSTRACT: A simple auth module for a site

#pod =head1 SYNOPSIS
#pod
#pod     use Mojolicious::Lite;
#pod     plugin Yancy => {
#pod         backend => 'pg://localhost/mysite',
#pod         collections => {
#pod             users => {
#pod                 required => [ 'username', 'password' ],
#pod                 properties => {
#pod                     id => { type => 'integer', readOnly => 1 },
#pod                     username => { type => 'string' },
#pod                     password => { type => 'string', format => 'password' },
#pod                 },
#pod             },
#pod         },
#pod     };
#pod     app->yancy->plugin( 'Auth::Basic' => {
#pod         collection => 'users',
#pod         username_field => 'username',
#pod         password_field => 'password',
#pod         password_digest => {
#pod             type => 'SHA-1',
#pod         },
#pod     } );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin provides a basic authentication and authorization scheme for
#pod a L<Mojolicious> site using L<Yancy>. If a user is authenticated, they are
#pod then authorized to use the administration application and API.
#pod
#pod =head1 CONFIGURATION
#pod
#pod This plugin has the following configuration options.
#pod
#pod =over
#pod
#pod =item collection
#pod
#pod The name of the Yancy collection that holds users. Required.
#pod
#pod =item username_field
#pod
#pod The name of the field in the collection which is the user's identifier.
#pod This can be a user name, ID, or e-mail address, and is provided by the
#pod user during login.
#pod
#pod This field is optional. If not specified, the collection's ID field will
#pod be used. For example, if the collection uses the C<username> field as
#pod a unique identifier, we don't need to provide a C<username_field>.
#pod
#pod     plugin Yancy => {
#pod         collections => {
#pod             users => {
#pod                 'x-id-field' => 'username',
#pod                 properties => {
#pod                     username => { type => 'string' },
#pod                     password => { type => 'string' },
#pod                 },
#pod             },
#pod         },
#pod     };
#pod     app->yancy->plugin( 'Auth::Basic' => {
#pod         collection => 'users',
#pod         password_digest => { type => 'SHA-1' },
#pod     } );
#pod
#pod =item password_field
#pod
#pod The name of the field to use for the user's password. Defaults to C<password>.
#pod
#pod This field will automatically be set up to use the L</auth.digest> filter to
#pod properly hash the password when updating it.
#pod
#pod =item password_digest
#pod
#pod This is the hashing mechanism that should be used for passwords. There is no
#pod default, so you must configure one.
#pod
#pod This value should be a hash of digest configuration. The one required
#pod field is C<type>, and should be a type supported by the L<Digest> module:
#pod
#pod =over
#pod
#pod =item * MD5 (part of core Perl)
#pod
#pod =item * SHA-1 (part of core Perl)
#pod
#pod =item * SHA-256 (part of core Perl)
#pod
#pod =item * SHA-512 (part of core Perl)
#pod
#pod =item * Bcrypt (recommended)
#pod
#pod =back
#pod
#pod Additional fields are given as configuration to the L<Digest> module.
#pod Not all Digest types require additional configuration.
#pod
#pod     # Use Bcrypt for passwords
#pod     # Install the Digest::Bcrypt module first!
#pod     app->yancy->plugin( 'Auth::Basic' => {
#pod         password_digest => {
#pod             type => 'Bcrypt',
#pod             cost => 12,
#pod             salt => 'abcdefghnstuff',
#pod         },
#pod     } );
#pod
#pod =item route
#pod
#pod The root route that this auth module should protect. Defaults to
#pod protecting only the Yancy editor application.
#pod
#pod =back
#pod
#pod =head1 TEMPLATES
#pod
#pod To override these templates in your application, provide your own
#pod template with the same name.
#pod
#pod =over
#pod
#pod =item yancy/auth/login.html.ep
#pod
#pod This template displays the login form. The form should have two fields,
#pod C<username> and C<password>, and perform a C<POST> request to C<<
#pod url_for 'yancy.check_login' >>
#pod
#pod =item yancy/auth/unauthorized.html.ep
#pod
#pod This template displays an error message that the user is not authorized
#pod to view this page. This most-often appears when the user is not logged in.
#pod
#pod =item layouts/yancy/auth.html.ep
#pod
#pod The layout that Yancy uses when displaying the login form, the
#pod unauthorized error message, and other auth-related pages.
#pod
#pod =back
#pod
#pod =head1 FILTERS
#pod
#pod This module provides the following filters. See L<Yancy/Extended Field
#pod Configuration> for how to use filters.
#pod
#pod =head2 auth.digest
#pod
#pod Run the field value through the configured password L<Digest> object and
#pod store the Base64-encoded result instead.
#pod
#pod =head1 HELPERS
#pod
#pod This plugin adds the following Mojolicious helpers:
#pod
#pod =head2 yancy.auth.route
#pod
#pod The L<route object|Mojolicious::Routes::Route> that requires
#pod authentication.  Add your own routes as children of this route to
#pod require authentication for your own routes.
#pod
#pod     my $auth_route = $app->yancy->auth->route;
#pod     $auth_route->get( '/', sub {
#pod         my ( $c ) = @_;
#pod         return $c->render(
#pod             data => 'You are authorized to view this page',
#pod         );
#pod     } );
#pod
#pod =head2 yancy.auth.current_user
#pod
#pod Get/set the currently logged-in user. Returns C<undef> if no user is
#pod logged-in.
#pod
#pod     my $user = $c->yancy->auth->current_user
#pod         || return $c->render( status => 401, text => 'Unauthorized' );
#pod
#pod To set the current user, pass in the username.
#pod
#pod     $c->yancy->auth->current_user( $username );
#pod
#pod =head2 yancy.auth.get_user
#pod
#pod     my $user = $c->yancy->auth->get_user( $username );
#pod
#pod Get a user item by its C<username>.
#pod
#pod =head2 yancy.auth.check
#pod
#pod Check a username and password to authenticate a user. Returns true
#pod if the user is authenticated, or returns false.
#pod
#pod B<NOTE>: Does not change the currently logged-in user.
#pod
#pod     if ( $c->yancy->auth->check( $username, $password ) ) {
#pod         # Authentication succeeded
#pod         $c->yancy->auth->current_user( $username );
#pod     }
#pod
#pod =head2 yancy.auth.clear
#pod
#pod Clear the currently logged-in user (logout).
#pod
#pod     $c->yancy->auth->clear;
#pod
#pod =head1 SUBCLASSING AND CUSTOM AUTH
#pod
#pod This class is intended to be extended for custom authentication modules.
#pod You can replace any of the templates or helpers (above) that you need
#pod after calling this class's C<register> method.
#pod
#pod If this API is not enough to implement your authentication module,
#pod please let me know and we can add a solution. If all authentication
#pod modules have the same API, it will be better for users.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Digest>
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Plugin';
use Digest;

sub register {
    my ( $self, $app, $config ) = @_;
    # Prepare and validate backend data configuration
    die "Error configuring Auth::Basic plugin: No password digest type defined\n"
        unless $config->{password_digest} && $config->{password_digest}{type};

    my $coll = $config->{collection}
        || die "Error configuring Auth::Basic plugin: No collection defined\n";
    die sprintf(
        q{Error configuring Auth::Basic plugin: Collection "%s" not found}."\n",
        $coll,
    ) unless $app->yancy->config->{collections}{$coll};

    my $username_field = $config->{username_field};
    my $password_field = $config->{password_field} || 'password';

    my $digest_type = delete $config->{password_digest}{type};
    my $digest = eval {
        Digest->new( $digest_type, %{ $config->{password_digest} } )
    };
    if ( my $error = $@ ) {
        if ( $error =~ m{Can't locate Digest/${digest_type}\.pm in \@INC} ) {
            die sprintf(
                q{Error configuring Auth::Basic plugin: Password digest type "%s" not found}."\n",
                $digest_type,
            );
        }
        die "Error configuring Auth::Basic plugin: Error loading Digest module: $@\n";
    }

    $app->yancy->filter->add( 'auth.digest' => sub {
        my ( $name, $value, $field ) = @_;
        return $digest->add( $value )->b64digest;
    } );
    push @{ $app->yancy->config->{collections}{$coll}{properties}{$password_field}{'x-filter'} }, 'auth.digest';

    # Add login pages
    my $route = $config->{route} || $app->yancy->route;
    push @{ $app->renderer->classes }, __PACKAGE__;
    $route->get( '/login', \&_get_login, 'yancy.login_form' );
    $route->post( '/login', \&_post_login, 'yancy.check_login' );
    $route->get( '/logout', \&_get_logout, 'yancy.logout' );

    # Add authentication check
    my $auth_route = $route->under( sub {
        my ( $c ) = @_;
        # Check auth
        return 1 if $c->yancy->auth->current_user;
        # Render some unauthorized result
        if ( grep { $_ eq 'api' } @{ $c->req->url->path } ) {
            # Render JSON unauthorized response
            $c->render(
                handler => 'openapi', # XXX This started being necessary after Mojolicious::Plugin::OpenAPI 2.0
                status => 401,
                openapi => {
                    message => 'You are not authorized to view this page. Please log in.',
                    errors => [],
                },
            );
            return;
        }
        else {
            # Render HTML response
            $c->render( status => 401, template => 'yancy/auth/unauthorized' );
            return;
        }
    } );
    my @routes = @{ $route->children }; # Loop over copy while we modify original
    for my $r ( @routes ) {
        next if $r eq $auth_route; # Can't reparent ourselves or route disappears

        # Don't add auth to unauthed routes. We need to add the plugin's
        # routes first so that they are picked up before the `under` we
        # created, but now we're going back to add auth to all
        # previously-created routes, so we need to skip the ones that
        # must be visited by unauthed users.
        next if grep { $r->name eq $_ } qw( yancy.login_form yancy.check_login yancy.logout );

        $auth_route->add_child( $r );
    }
    $app->helper( 'yancy.auth.route' => sub { $auth_route } );

    # Add auth helpers
    $app->helper( 'yancy.auth.get_user' => sub {
        my ( $c, $username ) = @_;
        return $username_field
            ? $c->yancy->backend->list( $coll, { $username_field => $username }, { limit => 1 } )->{items}[0]
            : $c->yancy->backend->get( $coll, $username );
    } );
    $app->helper( 'yancy.auth.current_user' => sub {
        my ( $c, $username ) = @_;
        if ( $username ) {
            $c->session( username => $username );
        }
        return if !$c->session( 'username' );
        return $c->yancy->auth->get_user( $c->session( 'username' ) );
    } );
    $app->helper( 'yancy.auth.check' => sub {
        my ( $c, $username, $pass ) = @_;
        my $user = $c->yancy->auth->get_user( $username );
        my $check_pass = $digest->add( $pass )->b64digest;
        return $user->{ $password_field } eq $check_pass;
    } );
    $app->helper( 'yancy.auth.clear' => sub {
        my ( $c ) = @_;
        delete $c->session->{ username };
    } );

}

sub _get_login {
    my ( $c ) = @_;
    return $c->render( 'yancy/auth/login',
        return_to => $c->req->headers->referrer,
    );
}

sub _post_login {
    my ( $c ) = @_;
    my $user = $c->param( 'username' );
    my $pass = $c->param( 'password' );
    if ( $c->yancy->auth->check( $user, $pass ) ) {
        $c->yancy->auth->current_user( $user );
        my $to = $c->req->param( 'return_to' ) // $c->url_for( 'yancy.index' );
        $c->res->headers->location( $to );
        return $c->rendered( 303 );
    }
    $c->flash( error => 'Username or password incorrect' );
    return $c->render( 'yancy/auth/login',
        status => 400,
        user => $user,
        return_to => $c->req->param( 'return_to' ),
        login_failed => 1,
    );
}

sub _get_logout {
    my ( $c ) = @_;
    $c->yancy->auth->clear;
    $c->flash( info => 'Logged out' );
    return $c->render( 'yancy/auth/login' );
}

1;

=pod

=head1 NAME

Yancy::Plugin::Auth::Basic - A simple auth module for a site

=head1 VERSION

version 1.014

=head1 SYNOPSIS

    use Mojolicious::Lite;
    plugin Yancy => {
        backend => 'pg://localhost/mysite',
        collections => {
            users => {
                required => [ 'username', 'password' ],
                properties => {
                    id => { type => 'integer', readOnly => 1 },
                    username => { type => 'string' },
                    password => { type => 'string', format => 'password' },
                },
            },
        },
    };
    app->yancy->plugin( 'Auth::Basic' => {
        collection => 'users',
        username_field => 'username',
        password_field => 'password',
        password_digest => {
            type => 'SHA-1',
        },
    } );

=head1 DESCRIPTION

This plugin provides a basic authentication and authorization scheme for
a L<Mojolicious> site using L<Yancy>. If a user is authenticated, they are
then authorized to use the administration application and API.

=head1 CONFIGURATION

This plugin has the following configuration options.

=over

=item collection

The name of the Yancy collection that holds users. Required.

=item username_field

The name of the field in the collection which is the user's identifier.
This can be a user name, ID, or e-mail address, and is provided by the
user during login.

This field is optional. If not specified, the collection's ID field will
be used. For example, if the collection uses the C<username> field as
a unique identifier, we don't need to provide a C<username_field>.

    plugin Yancy => {
        collections => {
            users => {
                'x-id-field' => 'username',
                properties => {
                    username => { type => 'string' },
                    password => { type => 'string' },
                },
            },
        },
    };
    app->yancy->plugin( 'Auth::Basic' => {
        collection => 'users',
        password_digest => { type => 'SHA-1' },
    } );

=item password_field

The name of the field to use for the user's password. Defaults to C<password>.

This field will automatically be set up to use the L</auth.digest> filter to
properly hash the password when updating it.

=item password_digest

This is the hashing mechanism that should be used for passwords. There is no
default, so you must configure one.

This value should be a hash of digest configuration. The one required
field is C<type>, and should be a type supported by the L<Digest> module:

=over

=item * MD5 (part of core Perl)

=item * SHA-1 (part of core Perl)

=item * SHA-256 (part of core Perl)

=item * SHA-512 (part of core Perl)

=item * Bcrypt (recommended)

=back

Additional fields are given as configuration to the L<Digest> module.
Not all Digest types require additional configuration.

    # Use Bcrypt for passwords
    # Install the Digest::Bcrypt module first!
    app->yancy->plugin( 'Auth::Basic' => {
        password_digest => {
            type => 'Bcrypt',
            cost => 12,
            salt => 'abcdefghnstuff',
        },
    } );

=item route

The root route that this auth module should protect. Defaults to
protecting only the Yancy editor application.

=back

=head1 TEMPLATES

To override these templates in your application, provide your own
template with the same name.

=over

=item yancy/auth/login.html.ep

This template displays the login form. The form should have two fields,
C<username> and C<password>, and perform a C<POST> request to C<<
url_for 'yancy.check_login' >>

=item yancy/auth/unauthorized.html.ep

This template displays an error message that the user is not authorized
to view this page. This most-often appears when the user is not logged in.

=item layouts/yancy/auth.html.ep

The layout that Yancy uses when displaying the login form, the
unauthorized error message, and other auth-related pages.

=back

=head1 FILTERS

This module provides the following filters. See L<Yancy/Extended Field
Configuration> for how to use filters.

=head2 auth.digest

Run the field value through the configured password L<Digest> object and
store the Base64-encoded result instead.

=head1 HELPERS

This plugin adds the following Mojolicious helpers:

=head2 yancy.auth.route

The L<route object|Mojolicious::Routes::Route> that requires
authentication.  Add your own routes as children of this route to
require authentication for your own routes.

    my $auth_route = $app->yancy->auth->route;
    $auth_route->get( '/', sub {
        my ( $c ) = @_;
        return $c->render(
            data => 'You are authorized to view this page',
        );
    } );

=head2 yancy.auth.current_user

Get/set the currently logged-in user. Returns C<undef> if no user is
logged-in.

    my $user = $c->yancy->auth->current_user
        || return $c->render( status => 401, text => 'Unauthorized' );

To set the current user, pass in the username.

    $c->yancy->auth->current_user( $username );

=head2 yancy.auth.get_user

    my $user = $c->yancy->auth->get_user( $username );

Get a user item by its C<username>.

=head2 yancy.auth.check

Check a username and password to authenticate a user. Returns true
if the user is authenticated, or returns false.

B<NOTE>: Does not change the currently logged-in user.

    if ( $c->yancy->auth->check( $username, $password ) ) {
        # Authentication succeeded
        $c->yancy->auth->current_user( $username );
    }

=head2 yancy.auth.clear

Clear the currently logged-in user (logout).

    $c->yancy->auth->clear;

=head1 SUBCLASSING AND CUSTOM AUTH

This class is intended to be extended for custom authentication modules.
You can replace any of the templates or helpers (above) that you need
after calling this class's C<register> method.

If this API is not enough to implement your authentication module,
please let me know and we can add a solution. If all authentication
modules have the same API, it will be better for users.

=head1 SEE ALSO

L<Digest>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
@@ yancy/auth/login.html.ep
% layout 'yancy/auth';
<main id="app" class="container-fluid">
    <div class="row justify-content-md-center">
        <div class="col-md-4">
            <h1>Login</h1>
            % if ( stash 'login_failed' ) {
            <div class="login-error alert alert-danger" role="alert">
              Login failed: User or password incorrect!
            </div>
            % }
            <form action="<%= url_for 'yancy.check_login' %>" method="POST">
                <input type="hidden" name="return_to" value="<%= stash 'return_to' %>" />
                <div class="form-group">
                    <label for="yancy-username">Username</label>
                    <input class="form-control" id="yancy-username" name="username"
                        placeholder="username" value="<%= stash 'user' %>"
                    >
                </div>
                <div class="form-group">
                    <label for="yancy-password">Password</label>
                    <input type="password" class="form-control" id="yancy-password" name="password" placeholder="password">
                </div>
                <button class="btn btn-primary">Login</button>
            </form>
        </div>
    </div>
</main>

@@ yancy/auth/unauthorized.html.ep
% layout 'yancy/auth';
<main class="container-fluid">
    <div class="row">
        <div class="col">
            <h1>Unauthorized</h1>
            <p>You are not authorized to view this page. <a href="<%= url_for
            'yancy.login_form' %>">Please log in</a></p>
        </div>
    </div>
</main>

