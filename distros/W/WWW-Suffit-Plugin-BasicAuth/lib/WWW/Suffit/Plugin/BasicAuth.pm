package WWW::Suffit::Plugin::BasicAuth;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Plugin::BasicAuth - The Mojolicious Plugin for HTTP basic authentication and authorization

=head1 SYNOPSIS

    # in your startup
    $self->plugin('WWW::Suffit::Plugin::BasicAuth', {
            realm => "Strict Zone",
            authn_fail_render => {
                status => 401,
                json => {
                    status => 0,
                    message => "Basic authentication required!",
                },
            },
            authz_fail_render => {
                status => 403,
                json => {
                    status => 0,
                    message => "Forbidden!",
                },
            },
        });

    # in your routes
    sub index {
        my $self = shift;

        # Basic authentication
        return unless $self->is_basic_authenticated({ render_by_fail => 1 });

        # Basic Authorization
        return unless $self->is_basic_authorized({ render_by_fail => 1 });

        $self->render(...);
    }

    # or as condition in your startup
    $self->routes->get('/info')->requires(basic_authenticated => 1, basic_authorized => 1)
        ->to('alpha#info');

    # or bridged in your startup
    my $auth = $self->routes->under(sub {
        my $self = shift;

        # Basic authentication
        return unless $self->is_basic_authenticated({ render_by_fail => 1 });

        # Basic Authorization
        return unless $self->is_basic_authorized({ render_by_fail => 1 });

        return 1;
    });
    $auth->get('/info')->to('alpha#info');

=head1 DESCRIPTION

The Mojolicious Plugin for HTTP basic authentication and authorization

This plugin based on L<NoRFC::Server::Auth>

=head1 OPTIONS

This plugin supports the following options

=head2 authn

Authentication checker callback

    $self->plugin('WWW::Suffit::Plugin::BasicAuth', {authn => sub {
        my ($controller, $realm, $username, $password, $params) = @_;

        # ...

        return 1; # or 0 on fail
    }});

The B<$params> holds options from L</is_basic_authenticated> call directly

=head2 authz

Authorization checker callback

    $self->plugin('WWW::Suffit::Plugin::BasicAuth', {authz => sub {
        my ($controller, $params) = @_;

        # ...

        return 1; # or 0 on fail
    }});

The B<$params> holds options from L</is_basic_authorized> call directly

=head2 authn_fail_render

Defines what is to be rendered when the authenticated condition is not met

Set to a coderef which will be called with the following signature:

    sub {
        my $controller = shift;
        my $realm = shift;
        my $resp = shift; # See authn_fail_render
        ...
        return $hashref;
    }

The return value of the subroutine will be ignored if it evaluates to false.
If it returns a hash reference, it will be dereferenced and passed as-is
to the controller's C<render> function

If set directly to a hash reference, that will be passed to C<render> instead

=head2 authz_fail_render

Defines what is to be rendered when the authorized condition is not met

Set to a coderef which will be called with the following signature:

    sub {
        my $controller = shift;
        my $resp = shift; # See authz_fail_render
        ...
        return $hashref;
    }

See also L</authn_fail_render>

=head2 realm

    $self->plugin('WWW::Suffit::Plugin::BasicAuth', {realm => 'My Castle!'});

HTTP Realm, defaults to 'Strict Zone'

=head1 HELPERS

=head2 is_basic_authenticated

This helper performs credential validation and checks the authentication status

    my $authenticated = $self->is_basic_authenticated;
    my $authenticated = $self->is_basic_authenticated({
            render_by_fail => 1,
            authn => sub {
                my ($c, $in_realm, $in_user, $in_pass, $params) = @_;
                return 0 unless $in_user;
                return secure_compare($in_pass, "mypass") ? 1 : 0;
            },
            fail_render => {
                json => {
                    message => "Basic authentication required!",
                },
                status => 401,
            },
        });

=over 8

=item B<render_by_fail>

It enables rendering the fail response. See L</authn_fail_render>

=item B<authn>

It defines code of authentication

=item B<fail_render>

It is render parameters as L</authn_fail_render>

=back

=head2 is_basic_authorized

This helper checks the authorization status

    my $authorized = $self->is_basic_authorized;
    my $authorized = $self->is_basic_authorized({
            render_by_fail => 1,
            authz => sub {
                my ($c, $params) = @_;
                return 1; # Basic authorization tsatus
            },
            fail_render => {
                json => {
                    message => "Forbidden!",
                },
                status => 403,
            },

        });

=over 8

=item B<render_by_fail>

It enables rendering the fail response. See L</authz_fail_render>

=item B<authz>

It defines code of authorization

=item B<fail_render>

It is render parameters as L</authz_fail_render>

=back

=head1 METHODS

Internal methods

=head2 register

This method register the plugin and helpers in L<Mojolicious> application.

=head1 EXAMPLES

Examples of using

=head2 ROUTING VIA CONDITION

This plugin exports a routing condition you can use in order to limit
access to certain documents to only authenticated users.

    $self->routes->get('/info')->requires(basic_authenticated => 1, basic_authorized => 1)
        ->to('alpha#info');

Prior to Mojolicious 9, use "over" instead of "requires."

=head2 ROUTING VIA CALLBACK

If you want to be able to send people to a login page, you will have to use
the following:

    sub index {
        my $self = shift;

        $self->redirect_to('/login') and return 0
            unless($self->is_basic_authenticated && $self->is_basic_authorized);

        $self->render(...);
    }

=head2 ROUTING VIA BRIDGE

    my $auth = $self->routes->under(sub {
        my $self = shift;

        # Authentication
        return unless $self->is_basic_authenticated({
            render_by_fail => 1
        });

        # Authorization
        return unless $self->is_basic_authorized({
            render_by_fail => 1
        });

        return 1;
    });
    $auth->get('/info')->to('alpha#info');

=head1 SEE ALSO

L<Mojolicious>, L<NoRFC::Server::Auth>, L<Mojolicious::Plugin::Authentication>,
L<Mojolicious::Plugin::Authorization>, L<Mojolicious::Plugin::BasicAuth>,
L<Mojolicious::Plugin::HttpBasicAuth>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util qw/b64_decode/;

our $VERSION = '1.00';

sub register {
    my ($plugin, $app, $defaults) = @_; # $self = $plugin
    $defaults //= {};
    $defaults->{realm} //= 'Strict Zone';
    $defaults->{authn_fail_render_cb} = ref($defaults->{authn_fail_render}) eq 'CODE'
        ? $defaults->{authn_fail_render}
        : sub {
            my $c = shift; # controller
            my $realm = shift || $defaults->{realm};
            my $resp = shift || $defaults->{authn_fail_render};
            $c->res->headers->www_authenticate(sprintf('Basic realm="%s"', $realm));
            return $resp;
        };
    $defaults->{authz_fail_render_cb} = ref($defaults->{authz_fail_render}) eq 'CODE'
        ? $defaults->{authz_fail_render}
        : sub {
            my $c = shift; # $controller
            my $resp = shift || $defaults->{authz_fail_render};
            return $resp;
        };

    # Authentication condition + fail render
    $app->routes->add_condition(basic_authenticated => sub {
        my ($r, $c, $captures, $required) = @_;
        my $res = (!$required or $c->is_basic_authenticated);
        unless ($res) {
            my $render = $defaults->{authn_fail_render_cb}; # Code
            my $fail = $render->($c); # Call render, returns {}
            $c->render(%$fail) if $fail;
        }
        return $res;
    });

    # Authorization condition + fail render
    $app->routes->add_condition(basic_authorized => sub {
        my ($r, $c, $captures, $required) = @_;
        my $res = (!$required or $c->is_basic_authorized);
        unless ($res) {
            my $render = $defaults->{authz_fail_render_cb}; # Code
            my $fail = $render->($c); # Call render, returns {}
            $c->render(%$fail) if $fail;
        }
        return $res;
    });

    # Authentication checker (authn)
    $app->helper(is_basic_authenticated => sub {
        my $c = shift;
        my $params = shift // {};
        my %opt = (%$defaults, %$params); # Hashes merging

        # Define the authn callback
        my $authn = ref($opt{authn}) eq 'CODE' ? $opt{authn} : sub { 1 };

        # Get authorization string from request headers
        my $auth_string = $c->req->headers->authorization
            || $c->req->env->{'X_HTTP_AUTHORIZATION'} || $c->req->env->{'HTTP_AUTHORIZATION'} || '';
        if ($auth_string =~ /Basic\s+(.*)/) {
            $auth_string = $1;
        }
        my $auth_pair = b64_decode($auth_string);

        # Verification
        return 1 if $auth_pair && $authn->($c, $opt{realm}, split(/:/, $auth_pair, 2), $params);
           # $controller, $realm, $username, $password, $params

        # Render by fail
        if ($opt{render_by_fail}) {
            my $render = $opt{authn_fail_render_cb}; # Code
            my $fail = $render->($c, $opt{realm}, $opt{fail_render}); # Call render, returns {}
            $c->render(%$fail) if $fail;
        }

        # Not authenticated
        return 0;
    });

    # Authorization checker (authz)
    $app->helper(is_basic_authorized => sub {
        my $c = shift;
        my $params = shift // {};
        my %opt = (%$defaults, %$params); # Hashes merging

        # Define the authz callback
        my $authz = ref($opt{authz}) eq 'CODE' ? $opt{authz} : sub { 1 };

        # Verification
        return 1 if $authz->($c, $params); # $controller, $params

        # Render by fail
        if ($opt{render_by_fail}) {
            my $render = $opt{authz_fail_render_cb}; # Code
            my $fail = $render->($c, $opt{fail_render}); # Call render, returns {}
            $c->render(%$fail) if $fail;
        }

        # Not authorized
        return 0;
    });
}

1;

__END__
