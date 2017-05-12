package Zenoss::Router::Mib;
use strict;

use Moose::Role;
requires '_router_request', '_check_args';

#**************************************************************************
# Attributes
#**************************************************************************
has 'MIB_LOCATION' => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'zport/dmd/mib_router',
    init_arg    => undef,
);

has 'MIB_ACTION' => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'MibRouter',
    init_arg    => undef,
);

#**************************************************************************
# Public Functions
#**************************************************************************
#======================================================================
# mib_getTree
#======================================================================
sub mib_getTree {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            id  => '/zport/dmd/Mibs'
        }
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'getTree',
            data        => [$args],
        }
    );
} # END mib_getTree

#======================================================================
# mib_getOrganizerTree
#======================================================================
sub mib_getOrganizerTree {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['id'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'getOrganizerTree',
            data        => [$args],
        }
    );
} # END mib_getOrganizerTree

#======================================================================
# mib_addNode
#======================================================================
sub mib_addNode {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['contextUid', 'id', 'type'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'addNode',
            data        => [$args],
        }
    );
} # END mib_addNode

#======================================================================
# mib_addMIB
#======================================================================
sub mib_addMIB {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['package'],
        defaults    => {
            organizer   => '/',
        },
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'addMIB',
            data        => [$args],
        }
    );
} # END mib_addMIB

#======================================================================
# mib_deleteNode
#======================================================================
sub mib_deleteNode {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['uid'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'deleteNode',
            data        => [$args],
        }
    );
} # END mib_deleteNode

#======================================================================
# mib_moveNode
#======================================================================
sub mib_moveNode {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['uids', 'target'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'moveNode',
            data        => [$args],
        }
    );
} # END mib_moveNode

#======================================================================
# mib_getInfo
#======================================================================
sub mib_getInfo {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['uid'],
        defaults    => {
            useFieldSets    => JSON::true,
        }
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'getInfo',
            data        => [$args],
        }
    );
} # END mib_getInfo

#======================================================================
# mib_setInfo
#======================================================================
sub mib_setInfo {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['uid'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'setInfo',
            data        => [$args],
        }
    );
} # END mib_setInfo

#**************************************************************************
# Package end
#**************************************************************************
no Moose;

1;

__END__

=head1 NAME

Zenoss::Router::Mib - A JSON/ExtDirect interface to operations on MIBs

=head1 SYNOPSIS

    use Zenoss;
    my $api = Zenoss->connect(
        {
            username    => 'zenoss username',
            password    => 'zenoss password',
            url         => 'http://zenossinstance:8080',
        }
    );

    # Replace SOMEMETHOD with one of the available methods provided by this module
    my $response = $api->mib_SOMEMETHOD(
        {
            parameter1 => 'value',
            parameter2 => 'value',
        }
    );

=head1 DESCRIPTION

This module is NOT instantiated directly.  To call methods from this module create an
instance of L<Zenoss>.  This document serves as a resource of available Zenoss API
calls to L<Zenoss>.

=head1 METHODS

The following is a list of available methods available for interaction with the Zenoss API.
Please take note of the argument requirements, defaults and return content.

The documentation for this module was mostly taken from the Zenoss JSON API docs.  Keep in mind
that their (Zenoss Monitoring System) programming is based around python, so descriptions such as 
dictionaries will be represented as hashes in Perl.

B<Mib is now working in Zenoss 3.2 - but the API docs are sketchy.  You might need to trial and error to get things to work correctly.  I recommend using FireBug with the UI to see what parameters are supposed to be sent!>

=head2 $obj->device_getTree()

Not documented - however it likely returns the organizational structure of install mibs

=over

=item ARGUMENTS

id

=back

=over

=item REQUIRED ARGUMENTS

id

=back

=over

=item DEFAULT ARGUMENTS

{id => '/zport/dmd/Mibs}

=back

=over

=item RETURNS

data: ([dictionary])

=back

=head2 $obj->device_getOrganizerTree()

Not documented

=over

=item ARGUMENTS

id

=back

=over

=item REQUIRED ARGUMENTS

id

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

data: ([dictionary])

=back

=head2 $obj->device_addNode()

Add organizer or MIB

=over

=item ARGUMENTS

contextUid (string)

id (string)

type (string) - Can be either organizer or MIB

=back

=over

=item REQUIRED ARGUMENTS

id

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

tree: ([dictionary])

=back

=head2 $obj->device_deleteNode()

Delete node

=over

=item ARGUMENTS

uid (string)

=back

=over

=item REQUIRED ARGUMENTS

uid

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

tree: ([dictionary])

=back

=head2 $obj->device_moveNode()

Move a node from its current organizer to another

=over

=item ARGUMENTS

uids (list of strings)

target (string)

=back

=over

=item REQUIRED ARGUMENTS

uids

target

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

tree: ([dictionary])

=back

=head2 $obj->device_getInfo()

Returns the details of a single info object as well as the form describing its schema

=over

=item ARGUMENTS

uid (string)

useFieldSets (bool)

=back

=over

=item REQUIRED ARGUMENTS

uid

=back

=over

=item DEFAULT ARGUMENTS

{useFieldSets => JSON::true}

=back

=over

=item RETURNS

success: ([bool])

data: ([dictionary])

=back

=head2 $obj->device_setInfo()

Set info - no description

=over

=item ARGUMENTS

uid (string)

any vars that can be set?

=back

=over

=item REQUIRED ARGUMENTS

uid

any vars that can be set?

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

data: ([dictionary])

=back

=head1 SEE ALSO

=over

=item *

L<Zenoss>

=item *

L<Zenoss::Response>

=back

=head1 AUTHOR

Patrick Baker E<lt>patricksbaker@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Patrick Baker E<lt>patricksbaker@gmail.comE<gt>

This module is free software: you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

You can obtain the Artistic License 2.0 by either viewing the
LICENSE file provided with this distribution or by navigating
to L<http://opensource.org/licenses/artistic-license-2.0.php>.

=cut