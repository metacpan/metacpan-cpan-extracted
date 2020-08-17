package Yancy::Plugin::Auth::Github;
our $VERSION = '1.066';
# ABSTRACT: Authenticate using Github's OAuth2 provider

#pod =head1 SYNOPSIS
#pod
#pod     use Mojolicious::Lite;
#pod     plugin Yancy => {
#pod         backend => 'sqlite://myapp.db',
#pod     };
#pod     app->yancy->plugin( 'Auth::Github' => {
#pod         client_id => 'CLIENT_ID',
#pod         client_secret => $ENV{ OAUTH_GITHUB_SECRET },
#pod         schema => 'users',
#pod         username_field => 'username',
#pod         # TODO: Get other user information from Github, requesting
#pod         # scopes if necessary
#pod     } );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module allows authenticating using the Github OAuth2 API.
#pod
#pod This module extends the L<Yancy::Auth::Plugin::OAuth2> module to add
#pod Github features.
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
#pod The client ID, provided by Github.
#pod
#pod =head2 client_secret
#pod
#pod The client secret, provided by Github.
#pod
#pod =head2 login_label
#pod
#pod The label for the button to log in using Github. Defaults
#pod to C<Login with Github>.
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
#pod This plugin inherits all helpers from L<Yancy::Plugin::Auth::OAuth2>.
#pod
#pod =head1 TEMPLATES
#pod
#pod To override these templates, add your own at the designated path inside
#pod your app's C<templates/> directory.
#pod
#pod =head2 yancy/auth/github/login_form.html.ep
#pod
#pod Display the button to log in using Github.
#pod
#pod =head2 layouts/yancy/auth.html.ep
#pod
#pod The layout that Yancy uses when displaying the login form, the
#pod unauthorized error message, and other auth-related pages.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Yancy::Plugin::Auth>, L<Yancy::Plugin::Auth::OAuth2>
#pod
#pod =cut

use Mojo::Base 'Yancy::Plugin::Auth::OAuth2';
use Yancy::Util qw( currym match derp );
use Mojo::UserAgent;
use Mojo::URL;

has moniker => 'github';
has authorize_url => sub { Mojo::URL->new( 'https://github.com/login/oauth/authorize' ) };
has token_url => sub { Mojo::URL->new( 'https://github.com/login/oauth/access_token' ) };
has api_url => sub { Mojo::URL->new( 'https://api.github.com/' ) };
has schema =>;
has username_field => 'username';
has plugin_field =>;
has allow_register => 0;
has login_label => 'Login with Github';

sub init {
    my ( $self, $app, $config ) = @_;
    if ( $config->{collection} ) {
        $self->schema( $config->{collection} );
        derp "'collection' configuration in Auth::Github is now 'schema'. Please fix your configuration.\n";
    }
    for my $attr ( qw( schema username_field plugin_field allow_register ) ) {
        next if !$config->{ $attr };
        $self->$attr( $config->{ $attr } );
    }
    for my $url_attr ( qw( api_url ) ) {
        next if !$config->{ $url_attr };
        $self->$url_attr( Mojo::URL->new( $config->{ $url_attr } ) );
    }
    return $self->SUPER::init( $app, $config );
}

#pod =method current_user
#pod
#pod Returns the user row of the currently-logged-in user.
#pod
#pod =cut

sub current_user {
    my ( $self, $c ) = @_;
    my $username = $c->session->{yancy}{ $self->moniker }{ github_login } || return undef;
    return $self->_get_user( $c, $username );
}

#pod =method login_form
#pod
#pod Get a link to log in using Github.
#pod
#pod =cut

sub login_form {
    my ( $self, $c ) = @_;
    return $c->render_to_string(
        'yancy/auth/github/login_form',
        label => $self->login_label,
        url => $self->route->render,
    );
}

sub _get_user {
    my ( $self, $c, $username ) = @_;
    my $schema_name = $self->schema;
    my $schema = $c->yancy->schema( $schema_name );
    my $username_field = $self->username_field;
    my %search;
    if ( my $field = $self->plugin_field ) {
        $search{ $field } = $self->moniker;
    }
    if ( $username_field && $username_field ne $schema->{'x-id-field'} ) {
        $search{ $username_field } = $username;
        my ( $user ) = @{ $c->yancy->backend->list( $schema_name, \%search, { limit => 1 } )->{items} };
        return $user;
    }
    return $c->yancy->backend->get( $schema_name, $username );
}

sub _handle_auth {
    my ( $self, $c ) = @_;

    # Verify the CSRF from Github
    if ( my $code = $c->param( 'code' ) ) {
        if ( $c->param( 'state' ) ne $c->csrf_token ) {
            $c->render( status => 400, text => 'CSRF token failure' );
        }
    }

    return $self->SUPER::_handle_auth( $c );
}

sub get_authorize_url {
    my ( $self, $c ) = @_;
    my %client_info = (
        client_id => $self->client_id,
        state => $c->csrf_token,
    );
    return $self->authorize_url->clone->query( \%client_info );
}

sub handle_token_p {
    my ( $self, $c, $token ) = @_;
    my $api_url = $self->api_url->clone;
    $api_url->path->trailing_slash( '1' )->merge( 'user' );
    return $self->ua->get_p(
        $api_url,
        { Authorization => join( ' ', 'token', $token ) },
    )
    ->then( sub {
        my ( $tx ) = @_;
        my $login = $tx->res->json( '/login' );
        if ( !$login ) {
            $c->render( text => 'Error getting Github login: ' . $tx->res->body );
        }
        $c->session->{yancy}{ $self->moniker }{ github_login } = $login;
        if ( !$self->_get_user( $c, $login ) ) {
            if ( !$self->allow_register ) {
                $c->app->log->error( 'Registration not allowed (set allow_register)' );
                $c->stash( status => 403 );
                die 'Registration of new users is not allowed';
                return;
            }
            my $schema = $c->yancy->schema( $self->schema );
            $c->yancy->create(
                $self->schema,
                { $self->username_field || $schema->{'x-id-field'} || 'id' => $login },
            );
        }
    } )
    ->catch( sub {
        my ( $err ) = @_;
        $c->render( text => $err );
    } );
}

1;

__END__

=pod

=head1 NAME

Yancy::Plugin::Auth::Github - Authenticate using Github's OAuth2 provider

=head1 VERSION

version 1.066

=head1 SYNOPSIS

    use Mojolicious::Lite;
    plugin Yancy => {
        backend => 'sqlite://myapp.db',
    };
    app->yancy->plugin( 'Auth::Github' => {
        client_id => 'CLIENT_ID',
        client_secret => $ENV{ OAUTH_GITHUB_SECRET },
        schema => 'users',
        username_field => 'username',
        # TODO: Get other user information from Github, requesting
        # scopes if necessary
    } );

=head1 DESCRIPTION

This module allows authenticating using the Github OAuth2 API.

This module extends the L<Yancy::Auth::Plugin::OAuth2> module to add
Github features.

This module composes the L<Yancy::Auth::Plugin::Role::RequireUser> role
to provide the
L<require_user|Yancy::Auth::Plugin::Role::RequireUser/require_user>
authorization method.

=head1 METHODS

=head2 current_user

Returns the user row of the currently-logged-in user.

=head2 login_form

Get a link to log in using Github.

=head1 CONFIGURATION

This plugin has the following configuration options.

=head2 client_id

The client ID, provided by Github.

=head2 client_secret

The client secret, provided by Github.

=head2 login_label

The label for the button to log in using Github. Defaults
to C<Login with Github>.

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

This plugin inherits all helpers from L<Yancy::Plugin::Auth::OAuth2>.

=head1 TEMPLATES

To override these templates, add your own at the designated path inside
your app's C<templates/> directory.

=head2 yancy/auth/github/login_form.html.ep

Display the button to log in using Github.

=head2 layouts/yancy/auth.html.ep

The layout that Yancy uses when displaying the login form, the
unauthorized error message, and other auth-related pages.

=head1 SEE ALSO

L<Yancy::Plugin::Auth>, L<Yancy::Plugin::Auth::OAuth2>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
