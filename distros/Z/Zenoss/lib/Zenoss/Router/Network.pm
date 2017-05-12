package Zenoss::Router::Network;
use strict;

use Moose::Role;
with 'Zenoss::Router::Tree', 'Zenoss::MetaHelper';
requires '_router_request', '_check_args';
__PACKAGE__->_INSTALL_META_METHODS;

#**************************************************************************
# Attributes
#**************************************************************************
has 'NETWORK_LOCATION' => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'zport/dmd/network_router',
    init_arg    => undef,
);

has 'NETWORK_ACTION' => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'NetworkRouter',
    init_arg    => undef,
);

#**************************************************************************
# Public Functions
#**************************************************************************
#======================================================================
# network_discoverDevices
#======================================================================
sub network_discoverDevices {
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
            location    => $self->NETWORK_LOCATION,
            action      => $self->NETWORK_ACTION,
            method      => 'discoverDevices',
            data        => [$args],
        }
    );
} # END network_discoverDevices

#======================================================================
# network_addNode
#======================================================================
sub network_addNode {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['newSubnet', 'contextUid'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->NETWORK_LOCATION,
            action      => $self->NETWORK_ACTION,
            method      => 'addNode',
            data        => [$args],
        }
    );
} # END network_addNode

#======================================================================
# network_deleteNode
#======================================================================
sub network_deleteNode {
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
            location    => $self->NETWORK_LOCATION,
            action      => $self->NETWORK_ACTION,
            method      => 'deleteNode',
            data        => [$args],
        }
    );
} # END network_deleteNode

#======================================================================
# network_getTree
#======================================================================
sub network_getTree {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            id  => '/zport/dmd/Networks',
        },
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->NETWORK_LOCATION,
            action      => $self->NETWORK_ACTION,
            method      => 'getTree',
            data        => [$args],
        }
    );
} # END network_getTree

#======================================================================
# network_getInfo
#======================================================================
sub network_getInfo {
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
            location    => $self->NETWORK_LOCATION,
            action      => $self->NETWORK_ACTION,
            method      => 'getInfo',
            data        => [$args],
        }
    );
} # END network_getInfo

#======================================================================
# network_setInfo
#======================================================================
sub network_setInfo {
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
            location    => $self->NETWORK_LOCATION,
            action      => $self->NETWORK_ACTION,
            method      => 'setInfo',
            data        => [$args],
        }
    );
} # END network_setInfo

#======================================================================
# network_getIpAddresses
#======================================================================
sub network_getIpAddresses {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            start   => 0,
            limit   => 50,
            sort    => 'name',
            order   => 'ASC',
        },
        required    => ['uid'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->NETWORK_LOCATION,
            action      => $self->NETWORK_ACTION,
            method      => 'getIpAddresses',
            data        => [$args],
        }
    );
} # END network_getIpAddresses

#======================================================================
# network_removeIpAddresses
#======================================================================
sub network_removeIpAddresses {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        uids    => ['uids'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->NETWORK_LOCATION,
            action      => $self->NETWORK_ACTION,
            method      => 'removeIpAddresses',
            data        => [$args],
        }
    );
} # END network_removeIpAddresses

#**************************************************************************
# Package end
#**************************************************************************
no Moose;

1;

__END__

=head1 NAME

Zenoss::Router::Network - A JSON/ExtDirect interface to operations on networks

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
    my $response = $api->network_SOMEMETHOD(
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

=head2 $obj->network_discoverDevices()

Discover devices on a network.

=over

=item ARGUMENTS

uid (string) - Unique identifier of the network to discover

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

jobId: (integer) The id of the discovery job

=back

=head2 $obj->network_addNode()

Discover devices on a network.

=over

=item ARGUMENTS

newSubnet (string) - New subnet to add

contextUid (string) - Unique identifier of the network parent of the new subnet

=back

=over

=item REQUIRED ARGUMENTS

newSubnet

contextUid

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

newNode: (dictionary) An object representing the new subnet node

=back

=head2 $obj->network_deleteNode()

Delete a subnet.

=over

=item ARGUMENTS

uid (string) - Unique identifier of the subnet to delete

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

tree: (dictionary) An object representing the new network tree

=back

=head2 $obj->network_getTree()

Returns the tree structure of an organizer hierarchy where the root node is the organizer identified by the id parameter.

=over

=item ARGUMENTS

id (string) - Id of the root node of the tree to be returned.

=back

=over

=item REQUIRED ARGUMENTS

N/A

=back

=over

=item DEFAULT ARGUMENTS

{id => '/zport/dmd/Networks'}

=back

=over

=item RETURNS

Object representing the tree

=back

=head2 $obj->network_getInfo()

Returns a dictionary of the properties of an object

=over

=item ARGUMENTS

uid (string) - Unique identifier of an object

keys (list) - List of keys to include in the returned dictionary. If None then all keys will be returned

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

data: (dictionary) Object properties

=back

=head2 $obj->network_setInfo()

Main method for setting attributes on a device or device organizer. This method accepts any keyword argument for the property that you wish to set. The only required property is "uid".

=over

=item ARGUMENTS

uid (string) - Unique identifier of an object

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

Not documented

=back

=head2 $obj->network_getIpAddresses()

Given a subnet, get a list of IP addresses and their relations.

=over

=item ARGUMENTS

uid (string) - Unique identifier of a subnet

start (integer) - Offset to return the results from; used in pagination

limit (integer) - Number of items to return; used in pagination

sort (string) - Key on which to sort the return results

order (string) - Sort order; can be either 'ASC' or 'DESC'

=back

=over

=item REQUIRED ARGUMENTS

uid

=back

=over

=item DEFAULT ARGUMENTS

{start => 0, limit => 50, sort => 'name', order => 'ASC'}

=back

=over

=item RETURNS

Not documented

=back

=head2 $obj->network_removeIpAddresses()

Removes every ip address specified by uids that are not attached to any device

=over

=item ARGUMENTS

uids (list string) - List of uid's to remove IP addresses on

=back

=over

=item REQUIRED ARGUMENTS

uids

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

removedCount: (integer)

errorCount: (integer)

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