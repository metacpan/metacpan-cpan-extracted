# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Realm::GenericPrincipal;

=pod

=head1 NAME

Wombat::Realm::GenericPrincipal - generic security principal class

=head1 SYNOPSIS

=head1 DESCRIPTION

Generic implementation of B<Servlet::Util::Principal> that is
available for use by B<Wombat::Realm> implementations.

=cut

use base qw(Servlet::Util::Principal);
use fields qw(name password realm roles);
use strict;
use warnings;

=pod

=head1 CONSTRUCTOR

=over

=item new()

Construct and return a B<Wombat::Realm::GenericPrincipal> instance,
initializing fields appropriately. If subclasses override the
constructor, they must be sure to call

  $self->SUPER::new();

=back

=cut

sub new {
    my $self = shift;
    my $realm = shift;
    my $name = shift;
    my $password = shift;
    my $roles = shift;

    $self = fields::new($self) unless ref $self;

    $self->{name} = $name;
    $self->{password} = $password;
    $self->{realm} = $realm;
    $self->{roles} = $roles && ref $roles eq 'ARRAY' ?
        { map { $_ => 1 } @$roles } :
            {};

    return $self;
}

=pod

=head1 ACCESSOR METHODS

=over

=item getName()

Return the username of the user represented by this Principal.

=cut

sub getName {
    my $self = shift;

    return $self->{name};
}

=pod

=item getPassword()

Return the authentication credentials for the user represented by this
Principal.

=cut

sub getPassword {
    my $self = shift;

    return $self->{password};
}

=pod

=item getRealm()

Return the Realm with which this Principal is associated.

=cut

sub getRealm {
    my $self = shift;

    return $self->{realm};
}

=pod

=item getRoles()

Return the array of roles associated with this user.

=cut

sub getRoles {
    my $self = shift;

    my $roles = sort keys %{ $self->{roles} };

    return wantarray ? @$roles : $roles;
}

=pod

=back

=head1 PUBLIC METHODS

=over

=item hasRole($role)

Return true if this principal possesses the specified role, or false
otherwise.

B<Parameters:>

=over

=item $role

the name of the security role to be checked

=back

=cut

sub hasRole {
    my $self = shift;
    my $role = shift;

    return $self->{roles}->{$role};
}

=pod

=back

=head1 SEE ALSO

B<Servlet::Util::Principal>,
B<Wombat::Realm>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut

1;
__END__
