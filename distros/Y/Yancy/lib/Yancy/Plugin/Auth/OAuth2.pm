package Yancy::Plugin::Auth::OAuth2;
our $VERSION = '1.088';
# ABSTRACT: Authenticate using an OAuth2 provider

#pod =head1 SYNOPSIS
#pod
#pod     use Mojolicious::Lite;
#pod     plugin Yancy => {
#pod         backend => 'sqlite://myapp.db',
#pod     };
#pod     app->yancy->plugin( 'Auth::OAuth2' => {
#pod         client_id => 'CLIENT_ID',
#pod         client_secret => 'SECRET',
#pod         authorize_url => 'https://example.com/auth',
#pod         token_url => 'https://example.com/token',
#pod     } );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module allows authenticating using a standard OAuth2 provider by
#pod implementing L<the OAuth2 specification|https://tools.ietf.org/html/rfc6749>.
#pod
#pod OAuth2 provides no mechanism for transmitting any information about the
#pod user in question, so this auth may require some customization to be
#pod useful. Without some kind of information about the user, it is
#pod impossible to know if this is a new user or a returning user or to
#pod maintain any kind of account information for the user.
#pod
#pod This module composes the L<Yancy::Auth::Plugin::Role::RequireUser> role
#pod to provide the
#pod L<require_user|Yancy::Auth::Plugin::Role::RequireUser/require_user>
#pod authorization method.
#pod
#pod =head1 CONFIGURATION
#pod
#pod This plugin has the following configuration options.
#pod
#pod =head2 client_id
#pod
#pod The client ID, provided by the OAuth2 provider.
#pod
#pod =head2 client_secret
#pod
#pod The client secret, provided by the OAuth2 provider.
#pod
#pod =head2 authorize_url
#pod
#pod The URL to start the OAuth2 authorization process.
#pod
#pod =head2 token_url
#pod
#pod The URL to get an access token. The second step of the auth process.
#pod
#pod =head2 login_label
#pod
#pod The label for the button to log in using this OAuth2 provider. Defaults
#pod to C<Login>.
#pod
#pod =head2 Sessions
#pod
#pod This module uses L<Mojolicious
#pod sessions|https://mojolicious.org/perldoc/Mojolicious/Controller#session>
#pod to store the login information in a secure, signed cookie.
#pod
#pod To configure the default expiration of a session, use
#pod L<Mojolicious::Sessions
#pod default_expiration|https://mojolicious.org/perldoc/Mojolicious/Sessions#default_expiration>.
#pod
#pod     use Mojolicious::Lite;
#pod     # Expire a session after 1 day of inactivity
#pod     app->sessions->default_expiration( 24 * 60 * 60 );
#pod
#pod =head1 HELPERS
#pod
#pod This plugin has the following helpers.
#pod
#pod =head2 yancy.auth.current_user
#pod
#pod Get the current user from the session, if any. Returns C<undef> if no
#pod user was found in the session.
#pod
#pod     my $user = $c->yancy->auth->current_user
#pod         || return $c->render( status => 401, text => 'Unauthorized' );
#pod
#pod =head2 yancy.auth.require_user
#pod
#pod Validate there is a logged-in user and optionally that the user data has
#pod certain values. See L<Yancy::Plugin::Auth::Role::RequireUser/require_user>.
#pod
#pod     # Display the user dashboard, but only to logged-in users
#pod     my $auth_route = $app->routes->under( '/user', $app->yancy->auth->require_user );
#pod     $auth_route->get( '' )->to( 'user#dashboard' );
#pod
#pod =head2 yancy.auth.login_form
#pod
#pod Returns the rendered login button.
#pod
#pod     Login with OAuth2:
#pod     %= $c->yancy->auth->login_form
#pod
#pod =head2 yancy.auth.logout
#pod
#pod Log out any current account from any auth plugin. Use this in your own
#pod route handlers to perform a logout.
#pod
#pod =head1 TEMPLATES
#pod
#pod To override these templates, add your own at the designated path inside
#pod your app's C<templates/> directory.
#pod
#pod =head2 yancy/auth/oauth2/login_form.html.ep
#pod
#pod Display the button to log in using this OAuth2 provider.
#pod
#pod =head2 layouts/yancy/auth.html.ep
#pod
#pod The layout that Yancy uses when displaying the login form, the
#pod unauthorized error message, and other auth-related pages.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Yancy::Plugin::Auth>
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Plugin';
use Role::Tiny::With;
with 'Yancy::Plugin::Auth::Role::RequireUser';
use Yancy::Util qw( currym match );
use Mojo::UserAgent;
use Mojo::URL;

has ua => sub { Mojo::UserAgent->new };
has route =>;
has moniker => 'oauth2';
has client_id =>;
has client_secret =>;
has authorize_url =>;
has token_url =>;
has login_label => 'Login';
has logout_route =>;

sub register {
    my ( $self, $app, $config ) = @_;
    $self->init( $app, $config );
    $app->helper(
        'yancy.auth.current_user' => currym( $self, 'current_user' ),
    );
    $app->helper(
        'yancy.auth.logout' => currym( $self, 'logout' ),
    );
    $app->helper(
        'yancy.auth.login_form' => currym( $self, 'login_form' ),
    );
}

sub init {
    my ( $self, $app, $config ) = @_;
    for my $attr ( qw( moniker ua client_id client_secret login_label ) ) {
        next if !$config->{ $attr };
        $self->$attr( $config->{ $attr } );
    }
    for my $url_attr ( qw( authorize_url token_url ) ) {
        next if !$config->{ $url_attr };
        $self->$url_attr( Mojo::URL->new( $config->{ $url_attr } ) );
    }
    $self->route(
        $app->yancy->routify(
            $config->{route},
            '/yancy/auth/' . $self->moniker,
        )
    );
    $self->route->get( '' )->to( cb => currym( $self, '_handle_auth' ) );
    $self->logout_route(
        $self->route->get( '/logout' )->to( cb => currym( $self, '_handle_logout' ) )
            ->name( 'yancy.auth.' . $self->moniker . '.logout' )
    );
}

#pod =method current_user
#pod
#pod Returns the access token of the currently-logged-in user.
#pod
#pod =cut

sub current_user {
    my ( $self, $c ) = @_;
    return $c->session->{yancy}{ $self->moniker }{access_token} || undef;
}

#pod =method logout
#pod
#pod Clear any currently-logged-in user.
#pod
#pod =cut

sub logout {
    my ( $self, $c ) = @_;
    delete $c->session->{yancy}{ $self->moniker };
    return;
}

#pod =method login_form
#pod
#pod Get a link to log in using this OAuth2 provider.
#pod
#pod =cut

sub login_form {
    my ( $self, $c ) = @_;
    return $c->render_to_string(
        'yancy/auth/oauth2/login_form',
        label => $self->login_label,
        url => $self->route->render,
    );
}

sub _handle_auth {
    my ( $self, $c ) = @_;

    # This sub handles both steps of authentication. If we have a code,
    # we can get a token.
    if ( my $code = $c->param( 'code' ) ) {
        my %client_info = (
            client_id => $self->client_id,
            client_secret => $self->client_secret,
            code => $code,
        );
        $self->ua->post_p( $self->token_url, form => \%client_info )
            ->then( sub {
                my ( $tx ) = @_;
                my $token = $tx->res->body_params->param( 'access_token' );
                $c->session->{yancy}{ $self->moniker }{ access_token } = $token;
                $self->handle_token_p( $c, $token )
                    ->then( sub {
                        my $return_to = $c->session->{ yancy }{ $self->moniker }{ return_to };
                        $c->redirect_to( $return_to );
                    } )
                    ->catch( sub {
                        my ( $err ) = @_;
                        $c->render( text => $err );
                    } );
            } )
            ->catch( sub {
                my ( $err ) = @_;
                $c->render(
                    text => $err,
                );
            } );
        return $c->render_later;
    }

    # If we do not have a code, we need to get one
    my $to = $c->param( 'return_to' );

    # Do not allow return_to to redirect the user to another site.
    # http://cwe.mitre.org/data/definitions/601.html
    if ( $to && $to =~ m{^(?:\w+:|//)} ) {
        return $c->reply->exception(
            q{`return_to` can not contain URL scheme or host},
        );
    }
    elsif ( !$to && $c->req->headers->referrer !~ m{^(?:\w+:|//)} ) {
        $to = $c->req->headers->referrer;
    }
    elsif ( !$to ) {
        $to = '/';
    }

    $c->session->{yancy}{ $self->moniker }{ return_to } = $to;
    $c->redirect_to( $self->get_authorize_url( $c ) );
}

#pod =method get_authorize_url
#pod
#pod     my $url = $self->get_authorize_url( $c );
#pod
#pod Get a full authorization URL with query parameters. Override this in
#pod a subclass to customize the authorization parameters.
#pod
#pod =cut

sub get_authorize_url {
    my ( $self, $c ) = @_;
    my %client_info = (
        client_id => $self->client_id,
    );
    return $self->authorize_url->clone->query( \%client_info );
}

#pod =method handle_token_p
#pod
#pod     my $p = $self->handle_token_p( $c, $token );
#pod
#pod Handle the receipt of the token. Override this in a subclass to make any
#pod API requests to identify the user. Returns a L<Mojo::Promise> that will
#pod be fulfilled when the information is complete.
#pod
#pod =cut

sub handle_token_p {
    my ( $self, $c, $token ) = @_;
    return Mojo::Promise->new->resolve;
}

sub _handle_logout {
    my ( $self, $c ) = @_;
    $self->logout( $c );
    $c->res->code( 303 );
    my $redirect_to = $c->param( 'redirect_to' ) // $c->req->headers->referrer // '/';
    if ( $redirect_to eq $c->req->url->path ) {
        $redirect_to = '/';
    }
    return $c->redirect_to( $redirect_to );
}

1;

__END__

=pod

=head1 NAME

Yancy::Plugin::Auth::OAuth2 - Authenticate using an OAuth2 provider

=head1 VERSION

version 1.088

=head1 SYNOPSIS

    use Mojolicious::Lite;
    plugin Yancy => {
        backend => 'sqlite://myapp.db',
    };
    app->yancy->plugin( 'Auth::OAuth2' => {
        client_id => 'CLIENT_ID',
        client_secret => 'SECRET',
        authorize_url => 'https://example.com/auth',
        token_url => 'https://example.com/token',
    } );

=head1 DESCRIPTION

This module allows authenticating using a standard OAuth2 provider by
implementing L<the OAuth2 specification|https://tools.ietf.org/html/rfc6749>.

OAuth2 provides no mechanism for transmitting any information about the
user in question, so this auth may require some customization to be
useful. Without some kind of information about the user, it is
impossible to know if this is a new user or a returning user or to
maintain any kind of account information for the user.

This module composes the L<Yancy::Auth::Plugin::Role::RequireUser> role
to provide the
L<require_user|Yancy::Auth::Plugin::Role::RequireUser/require_user>
authorization method.

=head1 METHODS

=head2 current_user

Returns the access token of the currently-logged-in user.

=head2 logout

Clear any currently-logged-in user.

=head2 login_form

Get a link to log in using this OAuth2 provider.

=head2 get_authorize_url

    my $url = $self->get_authorize_url( $c );

Get a full authorization URL with query parameters. Override this in
a subclass to customize the authorization parameters.

=head2 handle_token_p

    my $p = $self->handle_token_p( $c, $token );

Handle the receipt of the token. Override this in a subclass to make any
API requests to identify the user. Returns a L<Mojo::Promise> that will
be fulfilled when the information is complete.

=head1 CONFIGURATION

This plugin has the following configuration options.

=head2 client_id

The client ID, provided by the OAuth2 provider.

=head2 client_secret

The client secret, provided by the OAuth2 provider.

=head2 authorize_url

The URL to start the OAuth2 authorization process.

=head2 token_url

The URL to get an access token. The second step of the auth process.

=head2 login_label

The label for the button to log in using this OAuth2 provider. Defaults
to C<Login>.

=head2 Sessions

This module uses L<Mojolicious
sessions|https://mojolicious.org/perldoc/Mojolicious/Controller#session>
to store the login information in a secure, signed cookie.

To configure the default expiration of a session, use
L<Mojolicious::Sessions
default_expiration|https://mojolicious.org/perldoc/Mojolicious/Sessions#default_expiration>.

    use Mojolicious::Lite;
    # Expire a session after 1 day of inactivity
    app->sessions->default_expiration( 24 * 60 * 60 );

=head1 HELPERS

This plugin has the following helpers.

=head2 yancy.auth.current_user

Get the current user from the session, if any. Returns C<undef> if no
user was found in the session.

    my $user = $c->yancy->auth->current_user
        || return $c->render( status => 401, text => 'Unauthorized' );

=head2 yancy.auth.require_user

Validate there is a logged-in user and optionally that the user data has
certain values. See L<Yancy::Plugin::Auth::Role::RequireUser/require_user>.

    # Display the user dashboard, but only to logged-in users
    my $auth_route = $app->routes->under( '/user', $app->yancy->auth->require_user );
    $auth_route->get( '' )->to( 'user#dashboard' );

=head2 yancy.auth.login_form

Returns the rendered login button.

    Login with OAuth2:
    %= $c->yancy->auth->login_form

=head2 yancy.auth.logout

Log out any current account from any auth plugin. Use this in your own
route handlers to perform a logout.

=head1 TEMPLATES

To override these templates, add your own at the designated path inside
your app's C<templates/> directory.

=head2 yancy/auth/oauth2/login_form.html.ep

Display the button to log in using this OAuth2 provider.

=head2 layouts/yancy/auth.html.ep

The layout that Yancy uses when displaying the login form, the
unauthorized error message, and other auth-related pages.

=head1 SEE ALSO

L<Yancy::Plugin::Auth>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
