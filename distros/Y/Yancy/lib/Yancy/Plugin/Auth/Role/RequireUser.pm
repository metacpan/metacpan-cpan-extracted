package Yancy::Plugin::Auth::Role::RequireUser;
our $VERSION = '1.088';
# ABSTRACT: Add authorization based on user attributes

#pod =head1 SYNOPSIS
#pod
#pod     use Mojolicious::Lite;
#pod     plugin Yancy => ...;
#pod
#pod     # Require any user
#pod     my $require_user = app->yancy->auth->require_user;
#pod     my $user = app->routes->under( '/user', $require_user );
#pod
#pod     # Require a user with the `is_admin` field set to true
#pod     my $require_admin = app->yancy->auth->require_user( { is_admin => 1 } );
#pod     my $admin = app->routes->under( '/admin', $require_admin );
#pod
#pod =head1 DESCRIPTION
#pod
#pod B<Note:> This module is C<EXPERIMENTAL> and its API may change before
#pod Yancy v2.000 is released.
#pod
#pod This plugin adds a simple authorization method to your site. All default
#pod Yancy auth plugins use this role to provide the C<yancy.auth.require_user>
#pod helper.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Yancy::Plugin::Auth>
#pod
#pod =cut

use Mojo::Base '-role';
use Yancy::Util qw( currym match );

#pod =method require_user
#pod
#pod     my $subref = $c->yancy->auth->require_user( \%match );
#pod
#pod Build a callback to validate there is a logged-in user, and optionally
#pod that the current user has certain fields set. C<\%match> is optional and
#pod is a L<SQL::Abstract where clause|SQL::Abstract/WHERE CLAUSES> matched
#pod with L<Yancy::Util/match>.
#pod
#pod     # Ensure the user is logged-in
#pod     my $user_cb = $app->yancy->auth->require_user;
#pod     my $user_only = $app->routes->under( $user_cb );
#pod
#pod     # Ensure the user's "is_admin" field is set to 1
#pod     my $admin_cb = $app->yancy->auth->require_user( { is_admin => 1 } );
#pod     my $admin_only = $app->routes->under( $admin_cb );
#pod
#pod =cut

sub require_user {
    my ( $self, $c, $where ) = @_;
    return sub {
        my ( $c ) = @_;
        #; say "Are you authorized? " . $c->yancy->auth->current_user;
        my $user = $c->yancy->auth->current_user;
        # If where isn't specified, or it's a plain scalar truth value
        if ( ( !$where || ( !ref $where && $where ) ) && $user ) {
            return 1;
        }
        if ( $where && match( $where, $user ) ) {
            return 1;
        }
        # XXX: Create `reply->unauthorized` helper
        $c->stash(
            template => 'yancy/auth/unauthorized',
            status => 401,
            logout_route => $self->logout_route->render,
        );
        $c->respond_to(
            json => {},
            html => {},
        );
        return undef;
    };
}

around register => sub {
    my ( $orig, $self, $app, $config ) = @_;
    $app->helper(
        'yancy.auth.require_user' => currym( $self, 'require_user' ),
    );
    $self->$orig( $app, $config );
};

1;

__END__

=pod

=head1 NAME

Yancy::Plugin::Auth::Role::RequireUser - Add authorization based on user attributes

=head1 VERSION

version 1.088

=head1 SYNOPSIS

    use Mojolicious::Lite;
    plugin Yancy => ...;

    # Require any user
    my $require_user = app->yancy->auth->require_user;
    my $user = app->routes->under( '/user', $require_user );

    # Require a user with the `is_admin` field set to true
    my $require_admin = app->yancy->auth->require_user( { is_admin => 1 } );
    my $admin = app->routes->under( '/admin', $require_admin );

=head1 DESCRIPTION

B<Note:> This module is C<EXPERIMENTAL> and its API may change before
Yancy v2.000 is released.

This plugin adds a simple authorization method to your site. All default
Yancy auth plugins use this role to provide the C<yancy.auth.require_user>
helper.

=head1 METHODS

=head2 require_user

    my $subref = $c->yancy->auth->require_user( \%match );

Build a callback to validate there is a logged-in user, and optionally
that the current user has certain fields set. C<\%match> is optional and
is a L<SQL::Abstract where clause|SQL::Abstract/WHERE CLAUSES> matched
with L<Yancy::Util/match>.

    # Ensure the user is logged-in
    my $user_cb = $app->yancy->auth->require_user;
    my $user_only = $app->routes->under( $user_cb );

    # Ensure the user's "is_admin" field is set to 1
    my $admin_cb = $app->yancy->auth->require_user( { is_admin => 1 } );
    my $admin_only = $app->routes->under( $admin_cb );

=head1 SEE ALSO

L<Yancy::Plugin::Auth>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
