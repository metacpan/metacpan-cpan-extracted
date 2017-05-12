package Zenoss::Router::Process;
use strict;

use Moose::Role;
with 'Zenoss::Router::Tree', 'Zenoss::MetaHelper';
requires '_router_request', '_check_args';
__PACKAGE__->_INSTALL_META_METHODS;

#**************************************************************************
# Attributes
#**************************************************************************
has 'PROCESS_LOCATION' => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'zport/dmd/process_router',
    init_arg    => undef,
);

has 'PROCESS_ACTION' => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'ProcessRouter',
    init_arg    => undef,
);

#**************************************************************************
# Public Functions
#**************************************************************************
#======================================================================
# process_getTree
#======================================================================
sub process_getTree {
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
            location    => $self->PROCESS_LOCATION,
            action      => $self->PROCESS_ACTION,
            method      => 'getTree',
            data        => [$args],
        }
    );
} # END process_getTree

#======================================================================
# process_moveProcess
#======================================================================
sub process_moveProcess {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['uid', 'targetUid'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->PROCESS_LOCATION,
            action      => $self->PROCESS_ACTION,
            method      => 'moveProcess',
            data        => [$args],
        }
    );
} # END process_moveProcess

#======================================================================
# process_getInfo
#======================================================================
sub process_getInfo {
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
            location    => $self->PROCESS_LOCATION,
            action      => $self->PROCESS_ACTION,
            method      => 'getInfo',
            data        => [$args],
        }
    );
} # END process_getInfo

#======================================================================
# process_setInfo
#======================================================================
sub process_setInfo {
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
            location    => $self->PROCESS_LOCATION,
            action      => $self->PROCESS_ACTION,
            method      => 'setInfo',
            data        => [$args],
        }
    );
} # END process_getInfo

#======================================================================
# process_getInstances
#======================================================================
sub process_getInstances {
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
            location    => $self->PROCESS_LOCATION,
            action      => $self->PROCESS_ACTION,
            method      => 'getInstances',
            data        => [$args],
        }
    );
} # END process_getInstances

#======================================================================
# process_getSequence
#======================================================================
sub process_getSequence {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {};

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->PROCESS_LOCATION,
            action      => $self->PROCESS_ACTION,
            method      => 'getSequence',
            data        => [$args],
        }
    );
} # END process_getSequence

#======================================================================
# process_setSequence
#======================================================================
sub process_setSequence {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['uids']
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->PROCESS_LOCATION,
            action      => $self->PROCESS_ACTION,
            method      => 'setSequence',
            data        => [$args],
        }
    );
} # END process_setSequence

#**************************************************************************
# Package end
#**************************************************************************
no Moose;

1;

__END__

=head1 NAME

Zenoss::Router::Process - A JSON/ExtDirect interface to operations on processes

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
    my $response = $api->process_SOMEMETHOD(
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

=head2 $obj->process_getTree()

Returns the tree structure of an organizer hierarchy where the root node is the organizer identified by the id parameter.

=over

=item ARGUMENTS

id (string) - Id of the root node of the tree to be returned

=back

=over

=item REQUIRED ARGUMENTS

id

target

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

Object representing the tree

=back

=head2 $obj->process_moveProcess()

Move a process or organizer from one organizer to another.

=over

=item ARGUMENTS

uid (string) - UID of the process or organizer to move

targetUid (string) - UID of the organizer to move to

=back

=over

=item REQUIRED ARGUMENTS

uid

targetUid

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

uid: (dictionary) The new uid for moved process or organizer

=back

=head2 $obj->process_getInfo()

Get the properties of a process.

=over

=item ARGUMENTS

uid (string) - Unique identifier of a process

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

data: (dictionary) Object representing a process's properties

=back

=head2 $obj->process_setInfo()

Set attributes on a process. This method accepts any keyword argument for the property that you wish to set. The only required property is "uid".

=over

=item ARGUMENTS

uid (string) - Unique identifier of a process

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

data: (dictionary) Object representing a process's new properties

=back

=head2 $obj->process_getInstances()

Get a list of instances for a process UID.

=over

=item ARGUMENTS

uid (string) - Process UID to get instances of

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

{start => 0, limit => 50, sort => 'name', dir => 'ASC'}

=back

=over

=item RETURNS

data: ([dictionary]) List of objects representing process instances

total: (integer) Total number of instances

=back

=head2 $obj->process_getSequence()

Get the current processes sequence.

=over

=item ARGUMENTS

NONE

=back

=over

=item REQUIRED ARGUMENTS

N/A

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

data: ([dictionary]) List of objects representing processes in sequence order

=back

=head2 $obj->process_setSequence()

Set the current processes sequence.

=over

=item ARGUMENTS

uids ([string]) - The set of process uid's in the desired sequence

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

Success message

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