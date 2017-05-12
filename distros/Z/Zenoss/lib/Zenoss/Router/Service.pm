package Zenoss::Router::Service;
use strict;

use Moose::Role;
with 'Zenoss::Router::Tree', 'Zenoss::MetaHelper';
requires '_router_request', '_check_args';
__PACKAGE__->_INSTALL_META_METHODS;

#**************************************************************************
# Attributes
#**************************************************************************
has 'SERVICE_LOCATION' => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'zport/dmd/service_router',
    init_arg    => undef,
);

has 'SERVICE_ACTION' => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'ServiceRouter',
    init_arg    => undef,
);

#**************************************************************************
# Public Functions
#**************************************************************************
#======================================================================
# service_addClass
#======================================================================
sub service_addClass {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['contextUid', 'id', 'posQuery'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->SERVICE_LOCATION,
            action      => $self->SERVICE_ACTION,
            method      => 'addClass',
            data        => [$args],
        }
    );
} # END service_addClass

#======================================================================
# service_query
#======================================================================
sub service_query {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            history => JSON::false,
            limit   => JSON::null,
            uid     => '/zport/dmd'
        }
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->SERVICE_LOCATION,
            action      => $self->SERVICE_ACTION,
            method      => 'query',
            data        => [$args],
        }
    );
} # END service_query

#======================================================================
# service_getTree
#======================================================================
sub service_getTree {
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
            location    => $self->SERVICE_LOCATION,
            action      => $self->SERVICE_ACTION,
            method      => 'getTree',
            data        => [$args],
        }
    );
} # END service_getTree

#======================================================================
# service_getOrganizerTree
#======================================================================
sub service_getOrganizerTree {
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
            location    => $self->SERVICE_LOCATION,
            action      => $self->SERVICE_ACTION,
            method      => 'getOrganizerTree',
            data        => [$args],
        }
    );
} # END service_getOrganizerTree

#======================================================================
# service_getInfo
#======================================================================
sub service_getInfo {
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
            location    => $self->SERVICE_LOCATION,
            action      => $self->SERVICE_ACTION,
            method      => 'getInfo',
            data        => [$args],
        }
    );
} # END service_getInfo

#======================================================================
# service_setInfo
#======================================================================
sub service_setInfo {
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
            location    => $self->SERVICE_LOCATION,
            action      => $self->SERVICE_ACTION,
            method      => 'setInfo',
            data        => [$args],
        }
    );
} # END service_setInfo

#======================================================================
# service_getInstances
#======================================================================
sub service_getInstances {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            start   => 0,
            limit   => 50,
            sort    => 'name',
            dir     => 'ASC',
        },
        required    => ['uid'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->SERVICE_LOCATION,
            action      => $self->SERVICE_ACTION,
            method      => 'getInstances',
            data        => [$args],
        }
    );
} # END service_getInstances

#======================================================================
# service_moveServices
#======================================================================
sub service_moveServices {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['sourceUids', 'targetUid'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->SERVICE_LOCATION,
            action      => $self->SERVICE_ACTION,
            method      => 'moveServices',
            data        => [$args],
        }
    );
} # END service_moveServices

#======================================================================
# service_getUnmonitoredStartModes
#======================================================================
sub service_getUnmonitoredStartModes {
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
            location    => $self->SERVICE_LOCATION,
            action      => $self->SERVICE_ACTION,
            method      => 'getUnmonitoredStartModes',
            data        => [$args],
        }
    );
} # END service_getUnmonitoredStartModes

#======================================================================
# service_getMonitoredStartModes
#======================================================================
sub service_getMonitoredStartModes {
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
            location    => $self->SERVICE_LOCATION,
            action      => $self->SERVICE_ACTION,
            method      => 'getMonitoredStartModes',
            data        => [$args],
        }
    );
} # END service_getMonitoredStartModes


#**************************************************************************
# Package end
#**************************************************************************
no Moose;

1;

__END__

=head1 NAME

Zenoss::Router::Service - A JSON/ExtDirect interface to operations on services

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
    my $response = $api->service_SOMEMETHOD(
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

=head2 $obj->service_addClass()

Add a new service class.

=over

=item ARGUMENTS

contextUid (string) - Unique ID of the service ogranizer to add new class to

id (string) - ID of the new service

posQuery (dictionary) - Object defining a query where the returned position will lie

=back

=over

=item REQUIRED ARGUMENTS

contextUid

id

posQuery

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

newIndex: (integer) Index of the newly added class in the query defined by posQuery

=back

=head2 $obj->service_query()

Retrieve a list of services based on a set of parameters.

=over

=item ARGUMENTS

limit (integer) - Number of items to return; used in pagination

start (integer) - Offset to return the results from; used in pagination

sort (string) - Key on which to sort the return results

dir (string) - Sort order; can be either 'ASC' or 'DESC'

params (dictionary) - Key-value pair of filters for this search.

uid (string) - Service class UID to query

=back

=over

=item REQUIRED ARGUMENTS

N/A

=back

=over

=item DEFAULT ARGUMENTS

{ limit => JSON::null, uid => '/zport/dmd' }

=back

=over

=item RETURNS

services: ([dictionary]) List of objects representing services

totalCount: (integer) Total number of services

hash: (string) Hashcheck of the current services state

disabled: (boolean) True if current user cannot manage services

=back

=head2 $obj->service_getTree()

Returns the tree structure of an organizer hierarchy.

=over

=item ARGUMENTS

id (string) - Id of the root node of the tree to be returned

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

Object representing the tree

=back

=head2 $obj->service_getOrganizerTree()

Returns the tree structure of an organizer hierarchy, only including organizers.

=over

=item ARGUMENTS

id (string) - Id of the root node of the tree to be returned

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

Object representing the organizer tree

=back

=head2 $obj->service_getInfo()

Get the properties of a service.

=over

=item ARGUMENTS

uid (string) - Unique identifier of a service

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

data: (dictionary) Object representing a service's properties

disabled: (boolean) True if current user cannot manage service

=back

=head2 $obj->service_setInfo()

Set attributes on a service. This method accepts any keyword argument for the property that you wish to set. The only required property is "uid".

=over

=item ARGUMENTS

uid (string) - Unique identifier of a service

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

Success message

=back

=head2 $obj->service_getInstances()

Get a list of instances for a service UID.

=over

=item ARGUMENTS

uid (string) - Service UID to get instances of

start (integer) - Offset to return the results from; used in pagination

params (dictionary) - Key-value pair of filters for this search.

limit (integer) - Number of items to return; used in pagination

sort (string) - Key on which to sort the return results

dir (string) - Sort order; can be either 'ASC' or 'DESC'

=back

=over

=item REQUIRED ARGUMENTS

uid

=back

=over

=item DEFAULT ARGUMENTS

{start => 0, limit => 50, sort => 'name', dir => 'ASC}

=back

=over

=item RETURNS

data: ([dictionary]) List of objects representing service instances

totalCount: (integer) Total number of instances

=back

=head2 $obj->service_moveServices()

Move service(s) from one organizer to another.

=over

=item ARGUMENTS

sourceUids ([string]) - UID(s) of the service(s) to move

targetUid (string) - UID of the organizer to move to

=back

=over

=item REQUIRED ARGUMENTS

sourceUids

targetUid

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

Success message

=back

=head2 $obj->service_getUnmonitoredStartModes()

Get a list of unmonitored start modes for a Windows service.

=over

=item ARGUMENTS

uid (string) - Unique ID of a Windows service.

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

data: ([string]) List of unmonitored start modes for a Windows service

=back

=head2 $obj->service_getMonitoredStartModes()

Get a list of monitored start modes for a Windows service.

=over

=item ARGUMENTS

uid (string) - Unique ID of a Windows service.

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

data: ([string]) List of monitored start modes for a Windows service

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
