# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Realm;

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Wombat::Realm - internal realm interface

=head1 SYNOPSIS

=head1 DESCRIPTION

This is a read-only interface for an underlying security realm used to
authenticate individual users and to identify the security roles
associated with those users. Realms can be attached at any Container
level but will typically only be attached to an Application or higher
level Container.

=head1 ACCESSOR METHODS

=over

=item getContainer()

Return the Container associated with this Realm.

=item setContainer($container)

Set the Container associated with this Realm.

B<Parameters:>

=over

=item $container

the B<Wombat::Container> associated with this Realm

=back

=back

=head1 PUBLIC METHODS

=over

=item authenticate ($username, $credentials)

Return the Principal associated with the specified username and
credentials, if there is one, or C<undef> otherwise.

B<Parameters>

=over

=item $username

username of the principal to be looked up

=item $credentials

password or other credentials to use in authenticating this username

=back

=item hasRole($principal, $role)

Return true if the specified Principal has the specified security
role within the context of this Realm, or false otherwise.

B<Parameters:>

=over

=item $principal

the B<Servlet::Util::Principal> for whom the role is to be checked

=item $role

the name of the security role to be checked

=back

=back

=head1 SEE ALSO

L<Servlet::Util::Principal>,
L<Wombat::Container>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
