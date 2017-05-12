#**************************************************************************
# Name:         Template.pm
#
# Description:  A JSON/ExtDirect interface to operations on templates
#
# Author:       Patrick Baker
#
# Version:      $Id$
#
#**************************************************************************
package Zenoss::Router::Template;
use strict;

use Moose::Role;
with 'Zenoss::Router::Tree', 'Zenoss::MetaHelper';
requires '_router_request', '_check_args';
__PACKAGE__->_INSTALL_META_METHODS;

#**************************************************************************
# Attributes
#**************************************************************************
has 'TEMPLATE_LOCATION' => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'zport/dmd/template_router',
    init_arg    => undef,
);

has 'TEMPLATE_ACTION' => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'TemplateRouter',
    init_arg    => undef,
);

#**************************************************************************
# Public Functions
#**************************************************************************
#======================================================================
# template_getTemplates
#======================================================================
sub template_getTemplates {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            id  => '/zport/dmd/Devices',
        }
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'getTemplates',
            data        => [$args],
        }
    );
} # END template_getTemplates

#======================================================================
# template_getDeviceClassTemplates
#======================================================================
sub template_getDeviceClassTemplates {
    my ($self, $args) = @_;
    $self->_croak("getDeviceClassTemplates is broken at the Zenoss API level");
} # END template_getDeviceClassTemplates

#======================================================================
# template_getAddTemplateTargets
#======================================================================
sub template_getAddTemplateTargets {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            query   => JSON::null,
        }
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'getAddTemplateTargets',
            data        => [$args],
        }
    );
} # END template_getAddTemplateTargets

#======================================================================
# template_addTemplate
#======================================================================
sub template_addTemplate {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['id', 'targetUid'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'addTemplate',
            data        => [$args],
        }
    );
} # END template_addTemplate

#======================================================================
# template_deleteTemplate
#======================================================================
sub template_deleteTemplate {
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
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'deleteTemplate',
            data        => [$args],
        }
    );
} # END template_deleteTemplate

#======================================================================
# template_getThresholds
#======================================================================
sub template_getThresholds {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            query   => '',
        },
        required    => ['uid'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'getThresholds',
            data        => [$args],
        }
    );
} # END template_getThresholds

#======================================================================
# template_getThresholdDetails
#======================================================================
sub template_getThresholdDetails {
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
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'getThresholdDetails',
            data        => [$args],
        }
    );
} # END template_getThresholdDetails

#======================================================================
# template_getDataPoints
#======================================================================
sub template_getDataPoints {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            query   => JSON::null,
        },
        required    => ['uid'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'getDataPoints',
            data        => [$args],
        }
    );
} # END template_getDataPoints

#======================================================================
# template_addDataPoint
#======================================================================
sub template_addDataPoint {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['dataSourceUid', 'name'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'addDataPoint',
            data        => [$args],
        }
    );
} # END template_addDataPoint

#======================================================================
# template_addDataSource
#======================================================================
sub template_addDataSource {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['templateUid', 'name', 'type'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'addDataSource',
            data        => [$args],
        }
    );
} # END template_addDataSource

#======================================================================
# template_getDataSources
#======================================================================
sub template_getDataSources {
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
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'getDataSources',
            data        => [$args],
        }
    );
} # END template_getDataSources

#======================================================================
# template_getDataSourceDetails
#======================================================================
sub template_getDataSourceDetails {
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
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'getDataSourceDetails',
            data        => [$args],
        }
    );
} # END template_getDataSourceDetails

#======================================================================
# template_getDataPointDetails
#======================================================================
sub template_getDataPointDetails {
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
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'getDataPointDetails',
            data        => [$args],
        }
    );
} # END template_getDataPointDetails

#======================================================================
# template_setInfo
#======================================================================
sub template_setInfo {
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
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'setInfo',
            data        => [$args],
        }
    );
} # END template_setInfo

#======================================================================
# template_addThreshold
#======================================================================
sub template_addThreshold {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['uid', 'thresholdType', 'thresholdId', 'dataPoints'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'addThreshold',
            data        => [$args],
        }
    );
} # END template_addThreshold

#======================================================================
# template_removeThreshold
#======================================================================
sub template_removeThreshold {
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
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'removeThreshold',
            data        => [$args],
        }
    );
} # END template_removeThreshold

#======================================================================
# template_getThresholdTypes
#======================================================================
sub template_getThresholdTypes {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            query   => JSON::null,
        },
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'getThresholdTypes',
            data        => [$args],
        }
    );
} # END template_getThresholdTypes

#======================================================================
# template_getDataSourceTypes
#======================================================================
sub template_getDataSourceTypes {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            query   => JSON::null,
        },
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'getDataSourceTypes',
            data        => [$args],
        }
    );
} # END template_getDataSourceTypes

#======================================================================
# template_getGraphs
#======================================================================
sub template_getGraphs {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            query   => JSON::null,
        },
        required    => ['uid'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'getGraphs',
            data        => [$args],
        }
    );
} # END template_getGraphs

#======================================================================
# template_addDataPointToGraph
#======================================================================
sub template_addDataPointToGraph {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            includeThresholds   => JSON::false,
        },
        required    => ['dataPointUid', 'graphUid'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'getGraphs',
            data        => [$args],
        }
    );
} # END template_addDataPointToGraph

#======================================================================
# template_getCopyTargets
#======================================================================
sub template_getCopyTargets {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            query   => '',
        },
        required    => ['uid'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'getCopyTargets',
            data        => [$args],
        }
    );
} # END template_getCopyTargets

#======================================================================
# template_copyTemplate
#======================================================================
sub template_copyTemplate {
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
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'copyTemplate',
            data        => [$args],
        }
    );
} # END template_copyTemplate

#======================================================================
# template_addGraphDefinition
#======================================================================
sub template_addGraphDefinition {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['templateUid', 'graphDefinitionId'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'addGraphDefinition',
            data        => [$args],
        }
    );
} # END template_addGraphDefinition

#======================================================================
# template_deleteDataSource
#======================================================================
sub template_deleteDataSource {
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
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'deleteDataSource',
            data        => [$args],
        }
    );
} # END template_deleteDataSource

#======================================================================
# template_deleteDataPoint
#======================================================================
sub template_deleteDataPoint {
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
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'deleteDataPoint',
            data        => [$args],
        }
    );
} # END template_deleteDataPoint

#======================================================================
# template_deleteGraphDefinition
#======================================================================
sub template_deleteGraphDefinition {
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
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'deleteGraphDefinition',
            data        => [$args],
        }
    );
} # END template_deleteGraphDefinition

#======================================================================
# template_deleteGraphPoint
#======================================================================
sub template_deleteGraphPoint {
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
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'deleteGraphPoint',
            data        => [$args],
        }
    );
} # END template_deleteGraphPoint

#======================================================================
# template_getGraphPoints
#======================================================================
sub template_getGraphPoints {
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
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'getGraphPoints',
            data        => [$args],
        }
    );
} # END template_getGraphPoints

#======================================================================
# template_getInfo
#======================================================================
sub template_getInfo {
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
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'getInfo',
            data        => [$args],
        }
    );
} # END template_getInfo

#======================================================================
# template_addThresholdToGraph
#======================================================================
sub template_addThresholdToGraph {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['graphUid', 'thresholdUid'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'addThresholdToGraph',
            data        => [$args],
        }
    );
} # END template_addThresholdToGraph

#======================================================================
# template_addCustomToGraph
#======================================================================
sub template_addCustomToGraph {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['graphUid', 'customId', 'customType'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'addCustomToGraph',
            data        => [$args],
        }
    );
} # END template_addCustomToGraph

#======================================================================
# template_getGraphInstructionTypes
#======================================================================
sub template_getGraphInstructionTypes {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            query   => '',
        }
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'getGraphInstructionTypes',
            data        => [$args],
        }
    );
} # END template_getGraphInstructionTypes

#======================================================================
# template_setGraphPointSequence
#======================================================================
sub template_setGraphPointSequence {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['uids'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'setGraphPointSequence',
            data        => [$args],
        }
    );
} # END template_setGraphPointSequence

#======================================================================
# template_getGraphDefinition
#======================================================================
sub template_getGraphDefinition {
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
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'getGraphDefinition',
            data        => [$args],
        }
    );
} # END template_getGraphDefinition

#======================================================================
# template_setGraphDefinition
#======================================================================
sub template_setGraphDefinition {
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
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'setGraphDefinition',
            data        => [$args],
        }
    );
} # END template_setGraphDefinition

#======================================================================
# template_setGraphDefinitionSequence
#======================================================================
sub template_setGraphDefinitionSequence {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['uids'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->TEMPLATE_LOCATION,
            action      => $self->TEMPLATE_ACTION,
            method      => 'setGraphDefinitionSequence',
            data        => [$args],
        }
    );
} # END template_setGraphDefinitionSequence

#**************************************************************************
# Package end
#**************************************************************************
no Moose;

1;

__END__

=head1 NAME

Zenoss::Router::Template - A JSON/ExtDirect interface to operations on templates

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
    my $response = $api->template_SOMEMETHOD(
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

=head2 $obj->template_getTemplates()

Get all templates.

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

List of objects representing the templates in tree hierarchy

=back

=head2 $obj->template_getDeviceClassTemplates()

Get all templates by device class. This will return a tree where device classes are nodes, and templates are leaves.

THIS IS CURRENTLY BROKEN AT THE ZENOSS API LEVEL

=head2 $obj->template_getAddTemplateTargets()

Get a list of available device classes where new templates can be added.

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

data: ([dictionary]) List of objects containing an available device class UID and a human-readable label for that class

=back

=head2 $obj->template_addTemplate()

Add a template to a device class.

=over

=item ARGUMENTS

id (string) - Unique ID of the template to add

targetUid (string) - Unique ID of the device class to add template to

=back

=over

=item REQUIRED ARGUMENTS

id

targetUid

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

nodeConfig: (dictionary) Object representing the added template

=back

=head2 $obj->template_deleteTemplate()

Delete a template.

=over

=item ARGUMENTS

uid (string) - Unique ID of the template to delete

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

=head2 $obj->template_getThresholds()

Get the thresholds for a template.

=over

=item ARGUMENTS

uid (string) - Unique ID of a template

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

List of objects representing representing thresholds

=back

=head2 $obj->template_getThresholdDetails()

Get a threshold's details.

=over

=item ARGUMENTS

uid (string) - Unique ID of a threshold

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

record: (dictionary) Object representing the threshold

form: (dictionary) Object representing an ExtJS form for the threshold

=back

=head2 $obj->template_getDataPoints()

Get a list of available data points for a template.

=over

=item ARGUMENTS

uid (string) - Unique ID of a template

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

data: ([dictionary]) List of objects representing data points

=back

=head2 $obj->template_addDataPoint()

Add a new data point to a data source.

=over

=item ARGUMENTS

dataSourceUid (string) - Unique ID of the data source to add data point to

name (string) - ID of the new data point

=back

=over

=item REQUIRED ARGUMENTS

dataSourceUid

name

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

Success message

=back

=head2 $obj->template_addDataSource()

Add a new data source to a template.

=over

=item ARGUMENTS

templateUid (string) - Unique ID of the template to add data source to

name (string) - ID of the new data source

type (string) - Type of the new data source. From getDataSourceTypes()

=back

=over

=item REQUIRED ARGUMENTS

templateUid

name

type

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

Success message

=back

=head2 $obj->template_getDataSources()

Get the data sources for a template.

=over

=item ARGUMENTS

id (string) - Unique ID of a template

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

List of objects representing representing data sources

=back

=head2 $obj->template_getDataSourceDetails()

Get a data source's details.

=over

=item ARGUMENTS

uid (string) - Unique ID of a data source

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

record: (dictionary) Object representing the data source

form: (dictionary) Object representing an ExtJS form for the data source

=back

=head2 $obj->template_getDataPointDetails()

Get a data point's details.

=over

=item ARGUMENTS

uid (string) - Unique ID of a data point

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

record: (dictionary) Object representing the data point

form: (dictionary) Object representing an ExtJS form for the data point

=back

=head2 $obj->template_setInfo()

Set attributes on an object. This method accepts any keyword argument for the property that you wish to set. The only required property is "uid".

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

data: (dictionary) The modified object

=back

=head2 $obj->template_addThreshold()

Add a threshold.

=over

=item ARGUMENTS

uid (string) - Unique identifier of template to add threshold to

thresholdType (string) - Type of the new threshold. From template_getThresholdTypes()

thresholdId (string) - ID of the new threshold

dataPoints ([string]) - List of data points to select for this threshold

=back

=over

=item REQUIRED ARGUMENTS

uid

thresholdType

thresholdId

dataPoints

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

Success message

=back

=head2 $obj->template_removeThreshold()

Remove a threshold.

=over

=item ARGUMENTS

uid (string) - Unique identifier of threshold to remove

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

=head2 $obj->template_getThresholdTypes()

Get a list of available threshold types.

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

List of objects representing threshold types

=back

=head2 $obj->template_getDataSourceTypes()

Get a list of available data source types.

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

List of objects representing data source types

=back

=head2 $obj->template_getGraphs()

Get the graph definitions for a template.

=over

=item ARGUMENTS

uid (string) - Unique ID of a template

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

List of objects representing representing graphs

=back

=head2 $obj->template_addDataPointToGraph()

Add a data point to a graph.

=over

=item ARGUMENTS

dataPointUid (string) - Unique ID of the data point to add to graph

graphUid (string) - Unique ID of the graph to add data point to

includeThresholds (boolean) - True to include related thresholds

=back

=over

=item REQUIRED ARGUMENTS

dataPointUid

graphUid

=back

=over

=item DEFAULT ARGUMENTS

{ includeThresholds => JSON::false }

=back

=over

=item RETURNS

Success message

=back

=head2 $obj->template_getCopyTargets()

Get a list of available device classes to copy a template to.

=over

=item ARGUMENTS

uid (string) - Unique ID of the template to copy

query (string) - Filter the returned targets' names based on this parameter

=back

=over

=item REQUIRED ARGUMENTS

uid

=back

=over

=item DEFAULT ARGUMENTS

{ query => '' }

=back

=over

=item RETURNS

data: ([dictionary]) List of objects containing an available device class UID and a human-readable label for that class

=back

=head2 $obj->template_copyTemplate()

Copy a template to a device or device class.

=over

=item ARGUMENTS

uid (string) - Unique ID of the template to copy

targetUid (string) - Unique ID of the device or device class to bind to template

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

Success message

=back

=head2 $obj->template_addGraphDefinition()

Add a new graph definition to a template.

=over

=item ARGUMENTS

templateUid (string) - Unique ID of the template to add graph definition to

graphDefinitionId (string) - ID of the new graph definition

=back

=over

=item REQUIRED ARGUMENTS

templateUid

graphDefinitionId

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

Success message

=back

=head2 $obj->template_deleteDataSource()

Delete a data source.

=over

=item ARGUMENTS

uid (string) - Unique ID of the data source to delete

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

=head2 $obj->template_deleteDataPoint()

Delete a data point.

=over

=item ARGUMENTS

uid (string) - Unique ID of the data point to delete

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

=head2 $obj->template_deleteGraphDefinition()

Delete a graph definition.

=over

=item ARGUMENTS

uid (string) - Unique ID of the graph definition to delete

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

=head2 $obj->template_deleteGraphPoint()

Delete a graph point.

=over

=item ARGUMENTS

uid (string) - Unique ID of the graph point to delete

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

=head2 $obj->template_getGraphPoints()

Get a list of graph points for a graph definition.

=over

=item ARGUMENTS

uid (string) - Unique ID of a graph definition

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

data: ([dictionary]) List of objects representing graph points

=back

=head2 $obj->template_getInfo()

Get the properties of an object.

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

data: (dictionary) Object properties

form: (dictionary) Object representing an ExtJS form for the object

=back

=head2 $obj->template_addThresholdToGraph()

Add a threshold to a graph definition.

=over

=item ARGUMENTS

graphUid (string) - Unique ID of the graph definition to add threshold to

thresholdUid (string) - Unique ID of the threshold to add

=back

=over

=item REQUIRED ARGUMENTS

graphUid

thresholdUid

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

Success message

=back

=head2 $obj->template_addCustomToGraph()

Add a custom graph point to a graph definition.

=over

=item ARGUMENTS

graphUid (string) - Unique ID of the graph definition to add graph point to

customId (string) - ID of the new custom graph point

customType (string) - Type of the new graph point. From getGraphInstructionTypes()

=back

=over

=item REQUIRED ARGUMENTS

graphUid

customId

customType

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

Success message

=back

=head2 $obj->template_getGraphInstructionTypes()

Get a list of available instruction types for graph points.

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

data: ([dictionary]) List of objects representing instruction types

=back

=head2 $obj->template_setGraphPointSequence()

Sets the sequence of graph points in a graph definition.

=over

=item ARGUMENTS

uids ([string]) - List of graph point UID's in desired order

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

=head2 $obj->template_getGraphDefinition()

Get a graph definition.

=over

=item ARGUMENTS

uid (string) - Unique ID of the graph definition to retrieve

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

data: (dictionary) Object representing a graph definition

=back

=head2 $obj->template_setGraphDefinition()

Set attributes on an graph definition. This method accepts any keyword argument for the property that you wish to set. Properties are enumerated via getGraphDefinition(). The only required property is "uid".

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

data: (dictionary) The modified object

=back

=head2 $obj->template_setGraphDefinitionSequence()

Sets the sequence of graph definitions.

=over

=item ARGUMENTS

uids ([string]) - List of graph definition UID's in desired order

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