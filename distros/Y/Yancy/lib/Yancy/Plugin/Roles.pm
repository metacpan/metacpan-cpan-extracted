package Yancy::Plugin::Roles;
our $VERSION = '1.074';
# ABSTRACT: Role-based access controls (RBAC)

#pod =head1 SYNOPSIS
#pod
#pod     plugin Yancy => ...;
#pod     plugin Auth => ...;
#pod     plugin Roles => {
#pod         schema => 'roles',
#pod         userid_field => 'username',
#pod     };
#pod
#pod =head1 DESCRIPTION
#pod
#pod B<Note:> This module is C<EXPERIMENTAL> and its API may change before
#pod Yancy v2.000 is released.
#pod
#pod This plugin provides user authorization based on roles. Roles are
#pod created by using the L</require_role> method. User accounts are provided
#pod by L<Yancy::Plugin::Auth> (or a subclass). Accounts are mapped to roles
#pod in the database.
#pod
#pod =head1 CONFIGURATION
#pod
#pod This plugin has the following configuration options.
#pod
#pod =head2 schema
#pod
#pod The name of the Yancy schema that holds role memberships. Required.
#pod
#pod =head2 userid_field
#pod
#pod The name of the field in the schema which is the user's identifier.
#pod This field should be named the same in both the user schema and the
#pod roles schema.
#pod
#pod =head2 role_field
#pod
#pod The name of the field in the schema which holds the role. Defaults to
#pod C<role>.
#pod
#pod =head1 HELPERS
#pod
#pod This plugin has the following helpers.
#pod
#pod =head2 yancy.auth.has_role
#pod
#pod Return true if the current user has the given role.
#pod
#pod     get '/admin' => sub {
#pod         my $c = shift;
#pod         return $c->reply->not_found unless $c->yancy->auth->has_role( 'admin' );
#pod     };
#pod
#pod =head2 yancy.auth.require_role
#pod
#pod Validate there is a logged-in user and that the user belongs to the given
#pod role(s). Returns a callback that can be used in C<under>.
#pod
#pod     my $require_admin = $app->yancy->auth->require_role( 'admin' );
#pod     my $admin_routes = $app->routes->under( '/admin', $require_admin );
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Yancy::Plugin::Auth>
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Plugin';
use Yancy::Util qw( currym );

has schema =>;
has userid_field =>;
has role_field => 'role';

sub register {
    my ( $self, $app, $config ) = @_;
    my $schema_name = $config->{schema}
        || die "Error configuring Roles plugin: No schema defined\n";
    $self->schema( $schema_name );

    my $schema = $app->yancy->schema( $schema_name )
        || die sprintf(
            q{Error configuring Roles plugin: Schema "%s" not found}."\n",
            $schema_name,
        );

    $self->userid_field( $config->{userid_field} );
    $self->role_field( $config->{role_field} ) if $config->{role_field};
    $app->helper(
        'yancy.auth.require_role' => currym( $self, 'require_role' ),
    );
    $app->helper(
        'yancy.auth.has_role' => currym( $self, 'has_role' ),
    );
}

sub require_role {
    my ( $self, $c, $role ) = @_;
    return sub {
        my ( $c ) = @_;
        return 1 if $self->has_role( $c, $role );
        # XXX: Create `reply->unauthorized` helper
        $c->stash(
            template => 'yancy/auth/unauthorized',
            status => 401,
        );
        $c->respond_to(
            json => {},
            html => {},
        );
        return undef;
    }
}

sub has_role {
    my ( $self, $c, $role ) = @_;
    my $user = $c->yancy->auth->current_user or return undef;
    my %search = (
        $self->userid_field => $user->{ $self->userid_field },
        $self->role_field => $role,
    );
    my ( $has_role ) = $c->yancy->list( $self->schema, \%search );
    return !!$has_role;
}

1;

__END__

=pod

=head1 NAME

Yancy::Plugin::Roles - Role-based access controls (RBAC)

=head1 VERSION

version 1.074

=head1 SYNOPSIS

    plugin Yancy => ...;
    plugin Auth => ...;
    plugin Roles => {
        schema => 'roles',
        userid_field => 'username',
    };

=head1 DESCRIPTION

B<Note:> This module is C<EXPERIMENTAL> and its API may change before
Yancy v2.000 is released.

This plugin provides user authorization based on roles. Roles are
created by using the L</require_role> method. User accounts are provided
by L<Yancy::Plugin::Auth> (or a subclass). Accounts are mapped to roles
in the database.

=head1 CONFIGURATION

This plugin has the following configuration options.

=head2 schema

The name of the Yancy schema that holds role memberships. Required.

=head2 userid_field

The name of the field in the schema which is the user's identifier.
This field should be named the same in both the user schema and the
roles schema.

=head2 role_field

The name of the field in the schema which holds the role. Defaults to
C<role>.

=head1 HELPERS

This plugin has the following helpers.

=head2 yancy.auth.has_role

Return true if the current user has the given role.

    get '/admin' => sub {
        my $c = shift;
        return $c->reply->not_found unless $c->yancy->auth->has_role( 'admin' );
    };

=head2 yancy.auth.require_role

Validate there is a logged-in user and that the user belongs to the given
role(s). Returns a callback that can be used in C<under>.

    my $require_admin = $app->yancy->auth->require_role( 'admin' );
    my $admin_routes = $app->routes->under( '/admin', $require_admin );

=head1 SEE ALSO

L<Yancy::Plugin::Auth>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
