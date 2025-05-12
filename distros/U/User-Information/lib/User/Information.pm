# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from user accounts


package User::Information;

use v5.20;
use strict;
use warnings;

use Carp;
use Data::Identifier;

use constant {
    SPECIAL_ME          => [],
    SPECIAL_LOCAL_NODE  => Data::Identifier->new(uuid => '081c3899-cc4f-4cbd-9590-c90d1321e24c')->register,

};
use constant PATH_ELEMENT_NS     => Data::Identifier->new(uuid => '533fd060-2b96-4aea-8b8d-56e0766e6e5d')->register;
use constant PATH_ELEMENT_TYPE   => Data::Identifier->new(
        uuid        => 'f1f59629-3237-4587-a365-7ce094806f6d',
        displayname => 'user-information-path-element',
        validate    => qr/^[0-9a-zA-Z_-]+$/,
        namespace   => PATH_ELEMENT_NS,
    )->register;

use User::Information::Base;

our $VERSION = v0.01;


#@returns User::Information::Base
sub lookup {
    my ($self, @args) = @_;
    my ($type, $request);

    if (scalar(@args) & 1) {
        $type = 'from';
    } else {
        $type = shift(@args) // croak 'No type given';
    }
    $request = shift(@args) // croak 'No request given';

    return User::Information::Base->_new($type => $request, @args);
}


#@returns User::Information::Base
sub me {
    my ($self, %opts) = @_;
    return $self->lookup(from => SPECIAL_ME, %opts);
}


#@returns User::Information::Base
sub local_node {
    my ($self, %opts) = @_;
    return state $local_node = $self->lookup(from => SPECIAL_LOCAL_NODE, %opts);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

User::Information - generic module for extracting information from user accounts

=head1 VERSION

version v0.01

=head1 SYNOPSIS

    use User::Information;

    my User::Information::Base $result = User::Information->me;

This module allows extracting information on user accounts.

=head1 METHODS

=head2 lookup

    my User::Information::Base $result = User::Information->lookup($type => $request, %opts);
    # or:
    my User::Information::Base $result = User::Information->lookup($request, %opts);
    # e.g.:
    my User::Information::Base $result = User::Information->lookup(sysuid => 1000);

Performs a lookup of a user.

The lookup is based on a I<type> and a I<request>. The I<request> depend on the I<type>.

The following types are supported:

=over

=item C<from>

This is used if I<request> is some blessed object can that be used for lookups.

=back

Currently the same options are supported as by L<User::Information::Base/attach>.

=head2 me

    my User::Information::Base $result = User::Information->me(%opts);

Looks up the current user including information known via the process's environ.

The same options as per L</lookup> are supported.

See also:
L</lookup>.

=head2 local_node

    my User::Information::Base $result = User::Information->local_node(%opts);

Looks up the local node (system). This is a singleton.

No options are defined as of now.

See also:
L</lookup>.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
