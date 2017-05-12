# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Deploy::SecurityConstraint;

=pod

=head1 NAME

Wombat::Deploy::SecurityConstraint - security-constraint deployment
descriptor element class

=head1 SYNOPSIS

=head1 DESCRIPTION

Representation of a security constraint object for a web application,
as specified in a I<security-constraint> element in the deployment
descriptor.

=cut

use fields qw(allRoles authConstraint authRoles collections displayName);
use fields qw(userConstraint);
use strict;
use warnings;

=pod

=head1 CONSTRUCTOR

=over

=item new()

Construct and return a B<Wombat::Deploy::SecurityConstraint> instance,
initializing fields appropriately.

=back

=cut

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;

    $self->{allRoles} = undef;
    $self->{authConstraint} = undef;
    $self->{authRoles} = {};
    $self->{collections} = {};
    $self->{displayName} = undef;
    $self->{userConstraint} = 'NONE';

    return $self;
}

=pod

=head1 ACCESSOR METHODS

=over

=item getAllRoles()

Return a flag indicating if the "all roles" wildcard is included in
this SecurityConstraint.

=cut

sub getAllRoles {
    my $self = shift;

    return $self->{allRoles};
}

=pod

=item getAuthConstraint()

Return a flag indication if an authorization constraint is included in
this SecurityConstraint. This is necessary to distinguish between an
auth-constraint with no roles (signifying no direct access at all) and
the lack of auth-constraint (which implies no access control checking).

=cut

sub getAuthConstraint {
    my $self = shift;

    return $self->{authConstraint};
}

=pod

=item setAuthConstraint($flag)

Set a flag indicating if an authorization constraint is included in
this SecurityConstraint.

B<Parameters:>

=over

=item $flag

a boolean value

=back

=cut

sub setAuthConstraint {
    my $self = shift;
    my $flag = shift;

    $self->{authConstraint} = $flag;

    return 1;
}

=pod

=item getDisplayName()

Return the display name of this SecurityConstraint.

=cut

sub getDisplayName {
    my $self = shift;

    return $self->{getDisplayName};
}

=pod

=item setDisplayName($displayName)

Set the display name of this SecurityCosntraint.

B<Parameters:>

=over

=item $displayName

the display name

=back

=cut

sub setDisplayName {
    my $self = shift;
    my $displayName = shift;

    $self->{displayName} = $displayName;

    return 1;
}

=pod

=item getUserConstraint()

Return the user data constraint for this SecurityConstraint.

=cut

sub getUserConstraint {
    my $self = shift;

    return $self->{userConstraint};
}

=pod

=item setUserConstraint($userConstraint)

Set the user data constraint for this SecurityConstraint. Must be one
of I<NONE>, I<INTEGRAL> or I<CONFIDENTIAL>.

B<Parameters:>

=over

=item $userConstraint

the user data constraint

=back

=cut

sub setUserConstraint {
    my $self = shift;
    my $userConstraint = shift;

    $self->{userConstraint} = $userConstraint;

    return 1;
}

=pod

=back

=head1 PUBLIC METHODS

=over

=item addAuthRole($authRole)

Add an authorization role, which is a role name that will be permitted
access to the resources protected by this SecurityConstraint.

B<Parameters:>

=over

=item $authRole

the role name to be added

=back

=cut

sub addAuthRole {
    my $self = shift;
    my $role = shift;

    return 1 unless $role;

    if ($role eq '*') {
        $self->{allRoles} = 1;
    } else {
        $self->{authRoles}->{$role} = 1;
    }

    $self->{authConstraint} = 1;

    return 1;
}

=pod

=item hasAuthRole($role)

Return true if the specified role is permitted access to the resources
protected by this SecurityConstraint.

B<Parameters:>

=over

=item $role

the role name to be checked

=back

=cut

sub hasAuthRole {
    my $self = shift;
    my $role = shift;

    return $self->{authRoles}->{$role};
}

=pod

=item getAuthRoles()

Return an array containing the names of the roles that are permitted
access to the resources protected by this SecurityConstraint.

=cut

sub getAuthRoles {
    my $self = shift;

    my @roles = keys %{ $self->{authRoles} };

    return wantarray ? @roles : \@roles;
}

=pod

=item removeAuthRole($role)

Remove the specified role from the set of roles permitted to access
the resources protected by this SecurityConstraint.

B<Parameters:>

=over

=item $role

the name of the role to be removed

=back

=cut

sub removeAuthRole {
    my $self = shift;
    my $role = shift;

    delete $self->{authRoles}->{$role};

    return 1;
}

=pod

=item addCollection($collection)

Add a new web resource collection to those protected by this
SecurityConstraint.

B<Parameters:>

=over

=item $collection

the B<Wombat::Deploy::SecurityConstraint> to be added

=back

=cut

sub addCollection {
    my $self = shift;
    my $collection = shift;

    return 1 unless $collection;

    my $key = $collection->getName() || ref $collection;
    $self->{collections}->{$key} = $collection;

    return 1;
}

=pod

=item getCollection($name)

Return the named web resource collection or C<undef>.

B<Parameters:>

=over

=item $name

the name of the web resource collection

=back

=cut

sub getCollection {
    my $self = shift;
    my $name = shift;

    return $self->{collections}->{$name};
}

=pod

=item getCollections()

Return an array containing the web resource collections protected by
this SecurityConstraint.

=cut

sub getCollections {
    my $self = shift;

    my @collections = values %{ $self->{collections} };

    return wantarray ? @collections : \@collections;
}

=pod

=item removeCollection($collection)

Remove the specified web resource collection from those protected by
this SecurityConstraint.

B<Parameters:>

=over

=item $collection

the B<Wombat::Deploy::SecurityCollection> to be removed

=back

=cut

sub removeCollection {
    my $self = shift;
    my $collection = shift;

    return 1 unless $collection;

    my $key = $collection->getName() || ref $collection;
    delete $self->{collections}->{$key};

    return 1;
}

=pod

=item included($uri, $method)

Return true if the specified context-relative URI and associated HTTP
method are protected by this SecurityConstraint.

B<Parameters:>

=over

=item $uri

the uri to check

=item $method

the method being used

=back

=cut

sub included {
    my $self = shift;
    my $uri = shift;
    my $method = shift;

    return undef unless $method;

    for my $collection ($self->getCollections()) {
        next unless $collection->hasMethod($method);
        for my $pattern ($collection->getPatterns()) {
            return 1 if $self->matchPattern($uri, $pattern);
        }
    }

    return undef;
}

# private methods

sub matchPattern {
    my $self = shift;
    my $path = shift;
    my $pattern = shift;

    # normalize the argument
    $path ||= '/';
    $pattern ||= '/';

    # check for exact match
    return 1 if $path eq $pattern;

    # check for path prefix matching
    if ($pattern =~ m|^/| && $pattern =~ s|/\*$||) {
        return 1 unless $pattern; # "/*" is the same as "/"
        return $path =~ m|^$pattern|;
    }

    # check for suffix matching
    if ($pattern =~ m|^\*\.|) {
        return $path =~ m|$pattern$|;
    }

    # check for universal mapping
    return $pattern eq '/';
}

1;
__END__

=pod

=back

=head1 SEE ALSO

L<Wombat::Deploy::SecurityCollection>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut


