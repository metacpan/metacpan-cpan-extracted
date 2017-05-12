package Zenoss::Router::Tree;
use strict;

use Moose::Role;

#**************************************************************************
# Public methods
#**************************************************************************
#======================================================================
# addNode
#======================================================================
sub addNode {
    my ($self, $args, $router) = @_;
    $args = {} if !$args;

    # Get the router and action
    my $LOCATION = uc($router) . '_LOCATION';
    my $ACTION = uc($router) . '_ACTION';

    # Argument definition
    my $definition = {
        required    => ['type', 'contextUid', 'id']
    };
    
    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->$LOCATION,
            action      => $self->$ACTION,
            method      => 'addNode',
            data        => [$args],
        }
    );
} # END addNode

#======================================================================
# deleteNode
#======================================================================
sub deleteNode {
    my ($self, $args, $router) = @_;
    $args = {} if !$args;

    # Get the router and action
    my $LOCATION = uc($router) . '_LOCATION';
    my $ACTION = uc($router) . '_ACTION';
    
    # Argument definition
    my $definition = {
        required    => ['uid'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->$LOCATION,
            action      => $self->$ACTION,
            method      => 'deleteNode',
            data        => [$args],
        }
    );
} # END deleteNode

#======================================================================
# moveOrganizer
#======================================================================
sub moveOrganizer {
    my ($self, $args, $router) = @_;
    $args = {} if !$args;

    # Get the router and action
    my $LOCATION = uc($router) . '_LOCATION';
    my $ACTION = uc($router) . '_ACTION';

    # Argument definition
    my $definition = {
        required    => ['uid'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->$LOCATION,
            action      => $self->$ACTION,
            method      => 'moveOrganizer',
            data        => [$args],
        }
    );
} # END moveOrganizer

#**************************************************************************
# Package end
#**************************************************************************
no Moose;

1;

__END__

=head1 NAME

Zenoss::Router::Tree - A common base class for routers that have a hierarchical tree structure.

=head1 SYNOPSIS

    use Zenoss;
    my $api = Zenoss->connect(
        {
            username    => 'zenoss username',
            password    => 'zenoss password',
            url         => 'http://zenossinstance:8080',
        }
    );

    # Replace router and SOMEMETHOD() with one of the available methods provided by this module.
    # Note, that router will be replaced with something like device, network, process.  Please
    # read the DESCRIPTION for additional information.
    my $response = $api->router_SOMEMETHOD(
        {
            parameter1 => 'value',
            parameter2 => 'value',
        }
    );
    


=head1 DESCRIPTION

This module is NOT instantiated directly.  To call methods from this module create an
instance of L<Zenoss>.  This document serves as a resource of available Zenoss API
calls to L<Zenoss>.

The following Zenoss::Router:: modules implement methods from Zenoss::Router::Tree

=over

=item *

L<Zenoss::Router::Device>

=item *

L<Zenoss::Router::Network>

=item *

L<Zenoss::Router::Process>

=item *

L<Zenoss::Router::Service>

=item *

L<Zenoss::Router::Template>

=back

=head1 METHODS

The following is a list of available methods available for interaction with the Zenoss API.
Please take note of the argument requirements, defaults and return content.

The documentation for this module was mostly taken from the Zenoss JSON API docs.  Keep in mind
that their (Zenoss Monitoring System) programming is based around python, so descriptions such as 
dictionaries will be represented as hashes in Perl.

=head2 $obj->addNode()

Add a node to the existing tree underneath the node specified by the context UID

=over

=item ARGUMENTS

type (string) - Either 'class' or 'organizer'

contextUid (string) - Path to the node that will be the new node's parent (ex. /zport/dmd/Devices)

id (string) - Identifier of the new node, must be unique in the parent context

description (string) - Describes this new node 

=back

=over

=item REQUIRED ARGUMENTS

type

contextUid

id

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

Marshaled form of the created node

=back

=head2 $obj->deleteNode()

Deletes a node from the tree.
B<NOTE:> You can not delete a root node of a tree

=over

=item ARGUMENTS

uid (string) - Unique identifier of the node we wish to delete

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

msg: (string) Status message

=back

=head2 $obj->moveOrganizer()

Move the organizer uid to be underneath the organizer specified by the targetUid.

=over

=item ARGUMENTS

targetUid (string) - New parent of the organizer

organizerUid (string) - The organizer to move

=back

=over

=item REQUIRED ARGUMENTS

targetUid

organizerUid

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

data: (dictionary) Moved organizer

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