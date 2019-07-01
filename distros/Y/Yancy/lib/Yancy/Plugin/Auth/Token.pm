package Yancy::Plugin::Auth::Token;
our $VERSION = '1.035';
# ABSTRACT: A simple token-based auth

#pod =head1 SYNOPSIS
#pod
#pod     use Mojolicious::Lite;
#pod     plugin Yancy => {
#pod         backend => 'sqlite://myapp.db',
#pod         schema => {
#pod             tokens => {
#pod                 properties => {
#pod                     id => { type => 'integer', readOnly => 1 },
#pod                     username => { type => 'string' },
#pod                     token => { type => 'string' },
#pod                 },
#pod             },
#pod         },
#pod     };
#pod     app->yancy->plugin( 'Auth::Token' => {
#pod         schema => 'tokens',
#pod         username_field => 'username',
#pod         token_field => 'token',
#pod         token_digest => {
#pod             type => 'SHA-1',
#pod         },
#pod     } );
#pod
#pod =head1 DESCRIPTION
#pod
#pod B<Note:> This module is C<EXPERIMENTAL> and its API may change before
#pod Yancy v2.000 is released.
#pod
#pod This plugin provides a basic token-based authentication scheme for
#pod a site. Tokens are provided in the HTTP C<Authorization> header:
#pod
#pod     Authorization: Token 
#pod
#pod =head1 CONFIGURATION
#pod
#pod This plugin has the following configuration options.
#pod
#pod =head2 schema
#pod
#pod The name of the Yancy schema that holds tokens. Required.
#pod
#pod =head2 token_field
#pod
#pod The name of the field to use for the token. Defaults to C<token>. The
#pod token itself is meaningless except to authenticate a user. It must be
#pod unique, and it should be treated like a password.
#pod
#pod =head2 token_digest
#pod
#pod This is the hashing mechanism that should be used for creating new
#pod tokens via the L<add_token|/yancy.auth.add_token> helper. The default type is C<SHA-1>.
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
#pod =back
#pod
#pod Additional fields are given as configuration to the L<Digest> module.
#pod Not all Digest types require additional configuration.
#pod
#pod =head2 username_field
#pod
#pod The name of the field in the schema which is the user's identifier.
#pod This can be a user name, ID, or e-mail address, and is used to keep track
#pod of who owns the token.
#pod
#pod This field is optional. If not specified, no user name will be stored.
#pod
#pod =head1 HELPERS
#pod
#pod This plugin has the following helpers.
#pod
#pod =head2 yancy.auth.current_user
#pod
#pod Get the current user from the token, if any. Returns C<undef> if no token
#pod was passed or the token was not found in the database.
#pod
#pod     my $user = $c->yancy->auth->current_user
#pod         || return $c->render( status => 401, text => 'Unauthorized' );
#pod
#pod =head2 yancy.auth.add_token
#pod
#pod     $ perl myapp.pl eval 'app->yancy->auth->add_token( "username" )'
#pod
#pod Generate a new token and add it to the database. C<"username"> is the
#pod username for the token. The token will be generated as a base-64 encoded
#pod hash of the following input:
#pod
#pod =over
#pod
#pod =item * The username
#pod
#pod =item * The site's L<secret|https://mojolicious.org/perldoc/Mojolicious#secrets>
#pod
#pod =item * The current L<time|perlfunc/time>
#pod
#pod =item * A random number
#pod
#pod =back
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Yancy::Plugin::Auth>
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Plugin';
use Yancy::Util qw( currym derp );
use Digest;

has schema =>;
has username_field =>;
has token_field =>;
has token_digest =>;
has plugin_field => undef;
has moniker => 'token';

sub register {
    my ( $self, $app, $config ) = @_;
    $self->init( $app, $config );
    $app->helper(
        'yancy.auth.current_user' => currym( $self, 'current_user' ),
    );
    $app->helper(
        'yancy.auth.add_token' => currym( $self, 'add_token' ),
    );
    $app->helper(
        'yancy.auth.require_user' => currym( $self, 'require_user' ),
    );
}

sub init {
    my ( $self, $app, $config ) = @_;
    my $schema = $config->{schema} || $config->{collection}
        || die "Error configuring Auth::Token plugin: No schema defined\n";
    derp "'collection' configuration in Auth::Token is now 'schema'. Please fix your configuration.\n"
        if $config->{collection};
    die sprintf(
        q{Error configuring Auth::Token plugin: Schema "%s" not found}."\n",
        $schema,
    ) unless $app->yancy->schema( $schema );

    $self->schema( $schema );
    $self->username_field( $config->{username_field} );
    $self->token_field(
        $config->{token_field} || $config->{password_field} || 'token'
    );

    my $digest_type = delete $config->{token_digest}{type};
    if ( $digest_type ) {
        my $digest = eval {
            Digest->new( $digest_type, %{ $config->{token_digest} } )
        };
        if ( my $error = $@ ) {
            if ( $error =~ m{Can't locate Digest/${digest_type}\.pm in \@INC} ) {
                die sprintf(
                    q{Error configuring Auth::Token plugin: Token digest type "%s" not found}."\n",
                    $digest_type,
                );
            }
            die "Error configuring Auth::Token plugin: Error loading Digest module: $@\n";
        }
        $self->token_digest( $digest );
    }

    my $route = $config->{route} || $app->routes->any( '/yancy/auth/' . $self->moniker );
    $route->to( cb => currym( $self, 'check_token' ) );
}

sub current_user {
    my ( $self, $c ) = @_;
    return undef unless my $auth = $c->req->headers->authorization;
    return undef unless my ( $token ) = $auth =~ /^Token\ (\S+)$/;
    my $schema = $self->schema;
    my %search;
    $search{ $self->token_field } = $token;
    if ( my $field = $self->plugin_field ) {
        $search{ $field } = $self->moniker;
    }
    my @users = $c->yancy->list( $schema, \%search );
    if ( @users > 1 ) {
        die "Refusing to auth: Multiple users with the same token found";
        return undef;
    }
    return $users[0];
}

sub check_token {
    my ( $self, $c ) = @_;
    my $field = $self->username_field;
    if ( my $user = $self->current_user( $c ) ) {
        return $c->render(
            text => $field ? $user->{ $field } : 'Ok',
        );
    }
    return $c->render(
        status => 401,
        text => 'Unauthorized',
    );
}

sub login_form {
    # There is no login form for a token
    return undef;
}

sub add_token {
    my ( $self, $c, $username, %user ) = @_;
    my @parts = ( $username, $c->app->secrets->[0], $$, scalar time, int rand 1_000_000 );
    my $token = $self->token_digest->clone->add( join "", @parts )->b64digest;
    my $username_field = $self->username_field;
    $c->yancy->create( $self->schema, {
        ( $username_field ? ( $username_field => $username ) : () ),
        $self->token_field => $token,
        ( $self->plugin_field ? ( $self->plugin_field => $self->moniker ) : () ),
        %user,
    } );
    return $token;
}

sub require_user {
    my ( $self, $c ) = @_;
    return sub {
        my ( $c ) = @_;
        $c->yancy->auth->current_user && return 1;
        $c->stash(
            template => 'yancy/auth/unauthorized',
            status => 401,
        );
        $c->respond_to(
            json => {},
            html => {},
        );
        return undef;
    };
}

1;

__END__

=pod

=head1 NAME

Yancy::Plugin::Auth::Token - A simple token-based auth

=head1 VERSION

version 1.035

=head1 SYNOPSIS

    use Mojolicious::Lite;
    plugin Yancy => {
        backend => 'sqlite://myapp.db',
        schema => {
            tokens => {
                properties => {
                    id => { type => 'integer', readOnly => 1 },
                    username => { type => 'string' },
                    token => { type => 'string' },
                },
            },
        },
    };
    app->yancy->plugin( 'Auth::Token' => {
        schema => 'tokens',
        username_field => 'username',
        token_field => 'token',
        token_digest => {
            type => 'SHA-1',
        },
    } );

=head1 DESCRIPTION

B<Note:> This module is C<EXPERIMENTAL> and its API may change before
Yancy v2.000 is released.

This plugin provides a basic token-based authentication scheme for
a site. Tokens are provided in the HTTP C<Authorization> header:

    Authorization: Token 

=head1 CONFIGURATION

This plugin has the following configuration options.

=head2 schema

The name of the Yancy schema that holds tokens. Required.

=head2 token_field

The name of the field to use for the token. Defaults to C<token>. The
token itself is meaningless except to authenticate a user. It must be
unique, and it should be treated like a password.

=head2 token_digest

This is the hashing mechanism that should be used for creating new
tokens via the L<add_token|/yancy.auth.add_token> helper. The default type is C<SHA-1>.

This value should be a hash of digest configuration. The one required
field is C<type>, and should be a type supported by the L<Digest> module:

=over

=item * MD5 (part of core Perl)

=item * SHA-1 (part of core Perl)

=item * SHA-256 (part of core Perl)

=item * SHA-512 (part of core Perl)

=back

Additional fields are given as configuration to the L<Digest> module.
Not all Digest types require additional configuration.

=head2 username_field

The name of the field in the schema which is the user's identifier.
This can be a user name, ID, or e-mail address, and is used to keep track
of who owns the token.

This field is optional. If not specified, no user name will be stored.

=head1 HELPERS

This plugin has the following helpers.

=head2 yancy.auth.current_user

Get the current user from the token, if any. Returns C<undef> if no token
was passed or the token was not found in the database.

    my $user = $c->yancy->auth->current_user
        || return $c->render( status => 401, text => 'Unauthorized' );

=head2 yancy.auth.add_token

    $ perl myapp.pl eval 'app->yancy->auth->add_token( "username" )'

Generate a new token and add it to the database. C<"username"> is the
username for the token. The token will be generated as a base-64 encoded
hash of the following input:

=over

=item * The username

=item * The site's L<secret|https://mojolicious.org/perldoc/Mojolicious#secrets>

=item * The current L<time|perlfunc/time>

=item * A random number

=back

=head1 SEE ALSO

L<Yancy::Plugin::Auth>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
