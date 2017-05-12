package Zenoss::Router::DetailNav;
use strict;

use Moose::Role;
requires '_router_request', '_check_args';

#**************************************************************************
# Attributes
#**************************************************************************
has 'DETAILNAV_LOCATION' => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'zport/dmd/detailnav_router',
    init_arg    => undef,
);

has 'DETAILNAV_ACTION' => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'DetailNavRouter',
    init_arg    => undef,
);

#**************************************************************************
# Public Methods
#**************************************************************************
#======================================================================
# detailnav_getDetailNavConfigs
#======================================================================
sub detailnav_getDetailNavConfigs {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {};

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DETAILNAV_LOCATION,
            action      => $self->DETAILNAV_ACTION,
            method      => 'getDetailNavConfigs',
            data        => [$args],
        }
    );
} # END detailnav_getDetailNavConfigs

#======================================================================
# detailnav_getContextMenus
#======================================================================
sub detailnav_getContextMenus {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {};

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DETAILNAV_LOCATION,
            action      => $self->DETAILNAV_ACTION,
            method      => 'getContextMenus',
            data        => [$args],
        }
    );
} # END detailnav_getContextMenus

#======================================================================
# detailnav_getSecurityPermissions
#======================================================================
sub detailnav_getSecurityPermissions {
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
            location    => $self->DETAILNAV_LOCATION,
            action      => $self->DETAILNAV_ACTION,
            method      => 'getSecurityPermissions',
            data        => [$args],
        }
    );
} # END detailnav_getSecurityPermissions

#**************************************************************************
# Package end
#**************************************************************************
no Moose;

1;

__END__

=head1 NAME

Zenoss::Router::DetailNav - Router to Details navigation for given uid

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
    my $response = $api->detailnav_SOMEMETHOD(
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

The documentation here is a bit sketcky as I dont have all the information.  What I've placed here is what I know
from reading the Zenoss JSON API documentation.  In the event the method calls become clearer I will update this.

=head2 $obj->detailnav_getDetailNavConfigs()

return a list of Detail navigation configurations. Can be used to create navigation links. Format is: { id: <id of the configuration>, 'viewName': <view to display>, 'xtype': <Ext type for the panel>, 'text': <display name of the config info> }

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

Unknown

=back

=head2 $obj->detailnav_getContextMenus()

Unknown

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

Unknown

=back

=head2 $obj->detailnav_getSecurityPermissions()

Unknown

=over

=item ARGUMENTS

uid

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

Unknown

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
