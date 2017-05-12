package Zenoss::Router::Report;
use strict;

use Moose::Role;
requires '_router_request', '_check_args';

#**************************************************************************
# Attributes
#**************************************************************************
has 'REPORT_LOCATION' => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'zport/dmd/report_router',
    init_arg    => undef,
);

has 'REPORT_ACTION' => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'ReportRouter',
    init_arg    => undef,
);

#**************************************************************************
# Public Functions
#**************************************************************************
#======================================================================
# report_getReportTypes
#======================================================================
sub report_getReportTypes {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {};

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->REPORT_LOCATION,
            action      => $self->REPORT_ACTION,
            method      => 'getReportTypes',
            data        => [$args],
        }
    );
} # END report_getReportTypes

#======================================================================
# report_getTree
#======================================================================
sub report_getTree {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            id  => '/zport/dmd/Reports',
        },
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->REPORT_LOCATION,
            action      => $self->REPORT_ACTION,
            method      => 'getTree',
            data        => [$args],
        }
    );
} # END report_getTree

#======================================================================
# report_addNode
#======================================================================
sub report_addNode {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['nodeType', 'contextUid', 'id'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->REPORT_LOCATION,
            action      => $self->REPORT_ACTION,
            method      => 'addNode',
            data        => [$args],
        }
    );
} # END report_addNode

#======================================================================
# report_deleteNode
#======================================================================
sub report_deleteNode {
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
            location    => $self->REPORT_LOCATION,
            action      => $self->REPORT_ACTION,
            method      => 'deleteNode',
            data        => [$args],
        }
    );
} # END report_deleteNode

#======================================================================
# report_moveNode
#======================================================================
sub report_moveNode {
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
            location    => $self->REPORT_LOCATION,
            action      => $self->REPORT_ACTION,
            method      => 'moveNode',
            data        => [$args],
        }
    );
} # END report_moveNode

#**************************************************************************
# Package end
#**************************************************************************
no Moose;

1;

__END__

=head1 NAME

Zenoss::Router::Report - A JSON/ExtDirect interface to operations on reports

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
    my $response = $api->report_SOMEMETHOD(
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

=head2 $obj->report_getReportTypes()

Get the available report types.

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

menuText: ([string]) Human readable list of report types

reportTypes: ([string]) A list of the available report type

=back

=head2 $obj->report_getTree()

Returns the tree structure of an organizer hierarchy where the root node is the organizer identified by the id parameter.

=over

=item ARGUMENTS

id (string) - (optional) Id of the root node of the tree to be returned

=back

=over

=item REQUIRED ARGUMENTS

N/A

=back

=over

=item DEFAULT ARGUMENTS

{id => '/zport/dmd/Reports'}

=back

=over

=item RETURNS

Object representing the tree

=back

=head2 $obj->report_addNode()

Add a new report or report organizer.

=over

=item ARGUMENTS

nodeType (string) - Type of new node. Can either be 'organizer' or one of the report types returned from report_getReportTypes()

contextUid (string) - The organizer where the new node should be added

id (string) - The new node's ID

=back

=over

=item REQUIRED ARGUMENTS

nodeType

contextUid

id

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

tree: (dictionary) Object representing the new Reports tree

newNode: (dictionary) Object representing the added node

=back

=head2 $obj->report_deleteNode()

Remove a report or report organizer.

=over

=item ARGUMENTS

uid (string) - The UID of the node to delete

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

tree: (dictionary) Object representing the new Reports tree

=back

=head2 $obj->report_moveNode()

Move a report or report organizer from one organizer to another.

=over

=item ARGUMENTS

uids ([string]) - The UID's of nodes to move

target (string) - The UID of the target Report organizer

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

tree: (dictionary) Object representing the new Reports tree

newNode: (dictionary) Object representing the moved node

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
