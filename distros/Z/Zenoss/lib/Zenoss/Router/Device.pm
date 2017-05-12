package Zenoss::Router::Device;
use strict;

use Moose::Role;
with 'Zenoss::Router::Tree', 'Zenoss::MetaHelper';
requires '_router_request', '_check_args';
__PACKAGE__->_INSTALL_META_METHODS;

#**************************************************************************
# Attributes
#**************************************************************************
has DEVICE_LOCATION => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'zport/dmd/device_router',
    init_arg    => undef,
);

has DEVICE_ACTION => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'DeviceRouter',
    init_arg    => undef,
);

#**************************************************************************
# Public Functions
#**************************************************************************
#======================================================================
# device_addLocationNode
#======================================================================
sub device_addLocationNode {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['type', 'contextUid', 'id'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'addLocationNode',
            data        => [$args],
        }
    );
} # END device_addLocationNode

#======================================================================
# device_getTree
#======================================================================
sub device_getTree {
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
            method      => 'getTree',
            data        => [$args],
        }
    );
} # END device_getTree

#======================================================================
# device_getComponents
#======================================================================
sub device_getComponents {
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
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'getComponents',
            data        => [$args],
        }
    );
} # END device_getComponents

#======================================================================
# device_getComponentTree
#======================================================================
sub device_getComponentTree {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {};

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'getComponentTree',
            data        => [$args],
        }
    );
} # END device_getComponentTree

#======================================================================
# device_findComponentIndex
#======================================================================
sub device_findComponentIndex {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            sort    => 'name',
            dir     => 'ASC',
        },
        required    => ['componentUid'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'findComponentIndex',
            data        => [$args],
        }
    );
} # END device_findComponentIndex

#======================================================================
# device_getForm
#======================================================================
sub device_getForm {
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
            method      => 'getForm',
            data        => [$args],
        }
    );
} # END device_getForm

#======================================================================
# device_getInfo
#======================================================================
sub device_getInfo {
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
            method      => 'getInfo',
            data        => [$args],
        }
    );
} # END device_getInfo

#======================================================================
# device_setInfo
#======================================================================
sub device_setInfo {
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
} # END device_setInfo

#======================================================================
# device_setProductInfo
#======================================================================
sub device_setProductInfo {
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
            method      => 'setProductInfo',
            data        => [$args],
        }
    );
} # END device_setProductInfo

#======================================================================
# device_getDevices
#======================================================================
sub device_getDevices {
    my ($self, $args, $test) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            start   => 0,
            limit   => 50,
            sort    => 'name',
            dir     => 'ASC',
        }
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'getDevices',
            data        => [$args],
        }
    );
} # END device_getDevices

#======================================================================
# device_moveDevices
#======================================================================
sub device_moveDevices {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            sort    => 'name',
            dir     => 'ASC',
        },
        required    => ['uids', 'target', 'hashcheck'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'moveDevices',
            data        => [$args],
        }
    );
} # END device_moveDevices

#======================================================================
# device_pushChanges
#======================================================================
sub device_pushChanges {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            sort    => 'name',
            dir     => 'ASC',
        },
        required    => ['uids', 'hashcheck'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'pushChanges',
            data        => [$args],
        }
    );
} # END device_pushChanges


#======================================================================
# device_lockDevices
#======================================================================
sub device_lockDevices {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            updates     => JSON::false,
            deletion    => JSON::false,
            sendevent   => JSON::false,
            sort        => 'name',
            dir         => 'ASC',
        },
        required    => ['uids', 'hashcheck'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'lockDevices',
            data        => [$args],
        }
    );
} # END device_lockDevices

#======================================================================
# device_resetIp
#======================================================================
sub device_resetIp {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            sort    => 'name',
            dir     => 'ASC',
            ip      => '',
        },
        required    => ['uids', 'hashcheck'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'resetIp',
            data        => [$args],
        }
    );
} # END device_resetIp

#======================================================================
# device_resetCommunity
#======================================================================
sub device_resetCommunity {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            sort    => 'name',
            dir     => 'ASC',
        },
        required    => ['uids', 'hashcheck'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'resetCommunity',
            data        => [$args],
        }
    );
} # END device_resetCommunity

#======================================================================
# device_setProductionState
#======================================================================
sub device_setProductionState {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            sort    => 'name',
            dir     => 'ASC',
        },
        required    => ['uids', 'prodState', 'hashcheck'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'setProductionState',
            data        => [$args],
        }
    );
} # END device_setProductionState

#======================================================================
# device_setPriority
#======================================================================
sub device_setPriority {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            sort    => 'name',
            dir     => 'ASC',
        },
        required    => ['uids', 'priority', 'hashcheck'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'device_setPriority',
            data        => [$args],
        }
    );
} # END device_setPriority

#======================================================================
# device_setCollector
#======================================================================
sub device_setCollector {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            sort    => 'name',
            dir     => 'ASC',
        },
        required    => ['uids', 'collector', 'hashcheck'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'setCollector',
            data        => [$args],
        }
    );
} # END device_setCollector

#======================================================================
# device_setComponentsMonitored
#======================================================================
sub device_setComponentsMonitored {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            monitor => JSON::false,
            start   => 0,
            limit   => 50,
            sort    => 'name',
            dir     => 'ASC',
        },
        required    => ['uids', 'hashcheck'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'setComponentsMonitored',
            data        => [$args],
        }
    );
} # END device_setComponentsMonitored

#======================================================================
# device_lockComponents
#======================================================================
sub device_lockComponents {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            updates     => JSON::false,
            deletion    => JSON::false,
            sendEvent   => JSON::false,
            start       => 0,
            limit       => 50,
            sort        => 'name',
            dir         => 'ASC',
        },
        required    => ['uids', 'hashcheck'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'lockComponents',
            data        => [$args],
        }
    );
} # END device_lockComponents

#======================================================================
# device_deleteComponents
#======================================================================
sub device_deleteComponents {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            start       => 0,
            limit       => 50,
            sort        => 'name',
            dir         => 'ASC',
        },
        required    => ['uids', 'hashcheck'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'deleteComponents',
            data        => [$args],
        }
    );
} # END device_deleteComponents

#======================================================================
# device_removeDevices
#======================================================================
sub device_removeDevices {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            action  => 'remove',
            sort    => 'name',
            dir     => 'ASC',
        },
        required    => ['uids', 'hashcheck'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'removeDevices',
            data        => [$args],
        }
    );
} # END device_removeDevices

#======================================================================
# device_getEvents
#======================================================================
sub device_getEvents {
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
            method      => 'getEvents',
            data        => [$args],
        }
    );
} # END device_getEvents

#======================================================================
# device_loadRanges
#======================================================================
sub device_loadRanges {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            sort    => 'name',
            dir     => 'ASC',
        },
        required    => ['ranges', 'hashcheck'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'loadRanges',
            data        => [$args],
        }
    );
} # END device_loadRanges

#======================================================================
# device_loadComponentRanges
#======================================================================
sub device_loadComponentRanges {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            start   => 0,
            sort    => 'name',
            dir     => 'ASC',
        },
        required    => ['ranges', 'hashcheck'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'loadComponentRanges',
            data        => [$args],
        }
    );
} # END device_loadComponentRanges

#======================================================================
# device_getUserCommands
#======================================================================
sub device_getUserCommands {
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
            method      => 'getUserCommands',
            data        => [$args],
        }
    );
} # END device_getUserCommands

#======================================================================
# device_getProductionStates
#======================================================================
sub device_getProductionStates {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {};

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'getProductionStates',
            data        => [$args],
        }
    );
} # END device_getProductionStates

#======================================================================
# device_getPriorities
#======================================================================
sub device_getPriorities {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {};

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'getPriorities',
            data        => [$args],
        }
    );
} # END device_getPriorities

#======================================================================
# device_getCollectors
#======================================================================
sub device_getCollectors {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {};

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'getCollectors',
            data        => [$args],
        }
    );
} # END device_getCollectors

#======================================================================
# device_getDeviceClasses
#======================================================================
sub device_getDeviceClasses {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {};

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'getDeviceClasses',
            data        => [$args],
        }
    );
} # END device_getDeviceClasses

#======================================================================
# device_getManufacturerNames
#======================================================================
sub device_getManufacturerNames {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {};

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'getManufacturerNames',
            data        => [$args],
        }
    );
} # END device_getManufacturerNames

#======================================================================
# device_getHardwareProductNames
#======================================================================
sub device_getHardwareProductNames {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            manufacturer    => '',
        }
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'getHardwareProductNames',
            data        => [$args],
        }
    );
} # END device_getHardwareProductNames

#======================================================================
# device_getOSProductNames
#======================================================================
sub device_getOSProductNames {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            manufacturer    => '',
        }
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'getOSProductNames',
            data        => [$args],
        }
    );
} # END device_getOSProductNames

#======================================================================
# device_addDevice
#======================================================================
sub device_addDevice {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            snmpCommunity   => '',
            snmpPort        => 161,
            collector       => 'localhost',
            rackSlot        => 0,
            productionState => 1000,
            comments        => '',
            hwManufacturer  => '',
            hwProductName   => '',
            osManufacturer  => '',
            osProductName   => '',
            priority        => 3,
            tag             => '',
            serialNumber    => '',
        },
        required    => ['deviceName', 'deviceClass']
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'addDevice',
            data        => [$args],
        }
    );
} # END device_addDevice

#======================================================================
# device_addLocalTemplate
#======================================================================
sub device_addLocalTemplate {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['deviceUid', 'templateId'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'addLocalTemplate',
            data        => [$args],
        }
    );
} # END device_addLocalTemplate

#======================================================================
# device_removeLocalTemplate
#======================================================================
sub device_removeLocalTemplate {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['deviceUid', 'templateId'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'removeLocalTemplate',
            data        => [$args],
        }
    );
} # END device_removeLocalTemplate

#======================================================================
# device_getLocalTemplates
#======================================================================
sub device_getLocalTemplates {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            query   => JSON::null
        },
        required    => ['uid'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'getLocalTemplates',
            data        => [$args],
        }
    );
} # END device_getLocalTemplates

#======================================================================
# device_getTemplates
#======================================================================
sub device_getTemplates {
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
            method      => 'getTemplates',
            data        => [$args],
        }
    );
} # END device_getTemplates

#======================================================================
# device_getUnboundTemplates
#======================================================================
sub device_getUnboundTemplates {
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
            method      => 'getUnboundTemplates',
            data        => [$args],
        }
    );
} # END device_getUnboundTemplates

#======================================================================
# device_getBoundTemplates
#======================================================================
sub device_getBoundTemplates {
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
            method      => 'getBoundTemplates',
            data        => [$args],
        }
    );
} # END device_getBoundTemplates

#======================================================================
# device_setBoundTemplates
#======================================================================
sub device_setBoundTemplates {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['uid', 'templateIds'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'setBoundTemplates',
            data        => [$args],
        }
    );
} # END device_setBoundTemplates

#======================================================================
# device_resetBoundTemplates
#======================================================================
sub device_resetBoundTemplates {
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
            method      => 'resetBoundTemplates',
            data        => [$args],
        }
    );
} # END device_resetBoundTemplates

#======================================================================
# device_bindOrUnbindTemplate
#======================================================================
sub device_bindOrUnbindTemplate {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['uid', 'templateUid'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'bindOrUnbindTemplate',
            data        => [$args],
        }
    );
} # END device_bindOrUnbindTemplate

#======================================================================
# device_getOverridableTemplates
#======================================================================
sub device_getOverridableTemplates {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            query   => JSON::null
        },
        required    => ['uid'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'getOverridableTemplates',
            data        => [$args],
        }
    );
} # END device_getOverridableTemplates

#======================================================================
# device_clearGeocodeCache
#======================================================================
sub device_clearGeocodeCache {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {};

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'clearGeocodeCache',
            data        => [$args],
        }
    );
} # END device_clearGeocodeCache

#======================================================================
# device_getGraphDefs
#======================================================================
sub device_getGraphDefs {
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
            method      => 'getGraphDefs',
            data        => [$args],
        }
    );
} # END device_getGraphDefs

#======================================================================
# device_getGroups
#======================================================================
sub device_getGroups {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {};

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'getGroups',
            data        => [$args],
        }
    );
} # END device_getGroups

#======================================================================
# device_getLocations
#======================================================================
sub device_getLocations {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {};

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'getLocations',
            data        => [$args],
        }
    );
} # END device_getLocations

#======================================================================
# device_getModifications
#======================================================================
sub device_getModifications {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            types   => JSON::null
        },
        required        => ['id'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'getModifications',
            data        => [$args],
        }
    );
} # END device_getModifications

#======================================================================
# device_getSystems
#======================================================================
sub device_getSystems {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {};

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'getSystems',
            data        => [$args],
        }
    );
} # END device_getSystems

#======================================================================
# device_getZenProperties
#======================================================================
sub device_getZenProperties {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            start   => 0,
            dir     => 'ASC',
        },
        required    => ['uid'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'getZenProperties',
            data        => [$args],
        }
    );
} # END device_getZenProperties

#======================================================================
# device_getZenProperty
#======================================================================
sub device_getZenProperty {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['uid', 'zProperty'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'getZenProperty',
            data        => [$args],
        }
    );
} # END device_getZenProperty

#======================================================================
# device_deleteZenProperty
#======================================================================
sub device_deleteZenProperty {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['uid', 'zProperty'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'deleteZenProperty',
            data        => [$args],
        }
    );
} # END device_deleteZenProperty

#======================================================================
# device_setZenProperty
#======================================================================
sub device_setZenProperty {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['uid', 'zProperty', 'value'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->DEVICE_LOCATION,
            action      => $self->DEVICE_ACTION,
            method      => 'setZenProperty',
            data        => [$args],
        }
    );
} # END device_setZenProperty

#**************************************************************************
# Package end
#**************************************************************************
no Moose;

1;

__END__

=head1 NAME

Zenoss::Router::Device - A JSON/ExtDirect interface to operations on devices

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
    my $response = $api->device_SOMEMETHOD(
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

=head2 $obj->device_addLocationNode()

Adds a new location organizer specified by the parameter id to the parent organizer specified by contextUid.
contextUid must be a path to a Location.

=over

=item ARGUMENTS

type (string) - Node type (always 'organizer' in this case)

contextUid (string) - Path to the location organizer that will be the new node's parent (ex. /zport/dmd/Devices/Locations)

id (string) - The identifier of the new node

description (string) - Describes the new location

address (string) - Physical address of the new location

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

success: (bool) Success of node creation

nodeConfig: (dictionary) The new location's properties

=back

=head2 $obj->device_getTree()

Returns the tree structure of an organizer hierarchy where the root node is the organizer identified by the id parameter.

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

success: (bool) Success of node creation

Object representing the tree

=back

=head2 $obj->device_getComponents()

Retrieves all of the components at a given UID. This method allows for pagination.

=over

=item ARGUMENTS

uid (string) - Unique identifier of the device whose components are being retrieved

meta_type (string) - The meta type of the components to be retrieved 

keys (list) - List of keys to include in the returned dictionary. If None then all keys will be returned 

start (integer) - Offset to return the results from; used in pagination 

limit (integer) - Number of items to return; used in pagination 

sort (string) - Key on which to sort the return results; 

dir (string) - Sort order; can be either 'ASC' or 'DESC' 

name (regex) - Used to filter the results 

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

data: (dictionary) The components returned

totalCount: (integer) Number of items returned

hash: (string) Hashcheck of the current component state (to check whether components have changed since last query)

=back

=head2 $obj->device_getComponentTree()

Retrieves all of the components set up to be used in a tree.

=over

=item ARGUMENTS

uid (string) - Unique identifier of the root of the tree to retrieve

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

Component properties in tree form

=back

=head2 $obj->device_findComponentIndex()

Given a component uid and the component search criteria, this retrieves the position of the component in the results.

=over

=item ARGUMENTS

componentUid (string) - Unique identifier of the component whose index to return

uid (string) - Unique identifier of the device queried for components

meta_type (string) - The meta type of the components to retrieve 

sort (string) - Key on which to sort the return results 

dir (string) - Sort order; can be either 'ASC' or 'DESC' 

name (regex) - Used to filter the results 

=back

=over

=item REQUIRED ARGUMENTS

componentUid

=back

=over

=item DEFAULT ARGUMENTS

{sort => 'name', dir => 'ASC'}

=back

=over

=item RETURNS

index: (integer) Index of the component

=back

=head2 $obj->device_getForm()

Given an object identifier, this returns all of the editable fields on that object as well as their ExtJs xtype that one would use on a client side form.

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

form: (dictionary) form fields for the object

=back

=head2 $obj->device_getInfo()

Get the properties of a device or device organizer

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

disabled: (bool) If current user doesn't have permission to use setInfo

=back

=head2 $obj->device_setInfo()

Set attributes on a device or device organizer.

=over

=item ARGUMENTS

This method accepts any keyword argument for the property that you wish to set.

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

DirectResponse

=back

=head2 $obj->device_setProductInfo()

Sets the ProductInfo on a device. This method has the following valid keyword arguments:

=over

=item ARGUMENTS

uid (string) - Unique identifier of a device

hwManufacturer (string) - Hardware manufacturer

hwProductName (string) - Hardware product name

osManufacturer (string) - Operating system manufacturer

osProductName (string) - Operating system product name

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

=head2 $obj->device_getDevices()

Retrieves a list of devices. This method supports pagination.

=over

=item ARGUMENTS

uid (string) - Unique identifier of the organizer to get devices from

start (integer) - Offset to return the results from; used in pagination 

params (dictionary) - Key-value pair of filters for this search. Can be one of the following: name, ipAddress, deviceClass, or productionState 

limit (integer) - Number of items to return; used in pagination 

sort (string) - Key on which to sort the return results 

dir (string) - Sort order; can be either 'ASC' or 'DESC' 

=back

=over

=item REQUIRED ARGUMENTS

N/A

=back

=over

=item DEFAULT ARGUMENTS

{start => 0, limit => 50, sort => 'name', dir => 'ASC'}

=back

=over

=item RETURNS

devices: (list) Dictionaries of device properties

totalCount: (integer) Number of devices returned

hash: (string) Hashcheck of the current device state (to check whether devices have changed since last query)

=back

=head2 $obj->device_moveDevices()

Moves the devices specified by uids to the organizer specified by 'target'.

=over

=item ARGUMENTS

uids ([string]) - List of device uids to move

target (string) - Uid of the organizer to move the devices to

hashcheck (string) - Hashcheck for the devices (from getDevices())

ranges ([integer]) - List of two integers that are the min/max values of a range of uids to include 

uid (string) - Organizer to use when using ranges to get additional uids 

params (dictionary) - Key-value pair of filters for this search. Can be one of the following: name, ipAddress, deviceClass, or productionState 

sort (string) - Key on which to sort the return result 

dir (string) - Sort order; can be either 'ASC' or 'DESC' 

=back

=over

=item REQUIRED ARGUMENTS

uids

target

hashcheck

=back

=over

=item DEFAULT ARGUMENTS

{sort => 'name', dir => 'ASC'}

=back

=over

=item RETURNS

tree: ([dictionary]) Object representing the new device tree

exports: (integer) Number of devices moved

=back

=head2 $obj->device_pushChanges()

Push changes on device(s) configuration to collectors.

=over

=item ARGUMENTS

uids ([string]) - List of device uids to push changes

hashcheck (string) - Hashcheck for the devices (from getDevices())

ranges ([integer]) - List of two integers that are the min/max values of a range of uids to include 

uid (string) - Organizer to use when using ranges to get additional uids 

params (dictionary) - Key-value pair of filters for this search. Can be one of the following: name, ipAddress, deviceClass, or productionState 

sort (string) - Key on which to sort the return result 

dir (string) - Sort order; can be either 'ASC' or 'DESC' 

=back

=over

=item REQUIRED ARGUMENTS

uids

hashcheck

=back

=over

=item DEFAULT ARGUMENTS

{sort => 'name', dir => 'ASC'}

=back

=over

=item RETURNS

Success message

=back

=head2 $obj->device_lockDevices()

Lock device(s) from changes.

=over

=item ARGUMENTS

uids ([string]) - List of device uids to lock

hashcheck (string) - Hashcheck for the devices (from getDevices())

ranges ([integer]) - List of two integers that are the min/max values of a range of uids to include 

updates (boolean) - True to lock device from updates 

deletion (boolean) - True to lock device from deletion 

sendEvent (boolean) - True to send an event when an action is blocked by locking 

uid (string) - Organizer to use when using ranges to get additional uids 

params (dictionary) - Key-value pair of filters for this search. Can be one of the following: name, ipAddress, deviceClass, or productionState 

sort (string) - Key on which to sort the return result 

dir (string) - Sort order; can be either 'ASC' or 'DESC' 

=back

=over

=item REQUIRED ARGUMENTS

uids

hashcheck

=back

=over

=item DEFAULT ARGUMENTS

{updates => JSON::false, deletion => JSON::false, sendevent => JSON::false, sort => 'name', dir => 'ASC'}

=back

=over

=item RETURNS

Success or failure message

=back

=head2 $obj->device_resetIp()

Reset IP address(es) of device(s) to the results of a DNS lookup or a manually set address

=over

=item ARGUMENTS

uids ([string]) - List of device uids with IP's to reset

hashcheck (string) - Hashcheck for the devices (from getDevices())

uid (string) - Organizer to use when using ranges to get additional uids 

ranges ([integer]) - List of two integers that are the min/max values of a range of uids to include 

params (dictionary) - Key-value pair of filters for this search. Can be one of the following: name, ipAddress, deviceClass, or productionState 

sort (string) - Key on which to sort the return result 

dir (string) - Sort order; can be either 'ASC' or 'DESC' 

ip (string) - IP to set device to. Empty string causes DNS lookup 

=back

=over

=item REQUIRED ARGUMENTS

uids

hashcheck

=back

=over

=item DEFAULT ARGUMENTS

{sort => 'name', dir => 'ASC', ip => ''}

=back

=over

=item RETURNS

Success or failure message

=back

=head2 $obj->device_resetCommunity()

Reset community string of device(s)

=over

=item ARGUMENTS

uids ([string]) - List of device uids to reset

hashcheck (string) - Hashcheck for the devices (from getDevices())

uid (string) - Organizer to use when using ranges to get additional uids 

ranges ([integer]) - List of two integers that are the min/max values of a range of uids to include 

params (dictionary) - Key-value pair of filters for this search. Can be one of the following: name, ipAddress, deviceClass, or productionState 

sort (string) - Key on which to sort the return result 

dir (string) - Sort order; can be either 'ASC' or 'DESC' 

=back

=over

=item REQUIRED ARGUMENTS

uids

hashcheck

=back

=over

=item DEFAULT ARGUMENTS

{sort => 'name', dir => 'ASC'}

=back

=over

=item RETURNS

Success or failure message

=back

=head2 $obj->device_setProductionState()

Set the production state of device(s)

=over

=item ARGUMENTS

uids ([string]) - List of device uids to set

prodState (integer) - Production state to set device(s) to.

hashcheck (string) - Hashcheck for the devices (from getDevices())

uid (string) - Organizer to use when using ranges to get additional uids 

ranges ([integer]) - List of two integers that are the min/max values of a range of uids to include 

params (dictionary) - Key-value pair of filters for this search. Can be one of the following: name, ipAddress, deviceClass, or 

productionState 

sort (string) - Key on which to sort the return result 

dir (string) - Sort order; can be either 'ASC' or 'DESC' 

=back

=over

=item REQUIRED ARGUMENTS

uids

prodState

hashcheck

=back

=over

=item DEFAULT ARGUMENTS

{sort => 'name', dir => 'ASC'}

=back

=over

=item RETURNS

Success or failure message

=back

=head2 $obj->device_setPriority()

Set device(s) priority.

=over

=item ARGUMENTS

uids ([string]) - List of device uids to set

priority (integer) - Priority to set device(s) to.

hashcheck (string) - Hashcheck for the devices (from getDevices())

uid (string) - Organizer to use when using ranges to get additional uids 

ranges ([integer]) - List of two integers that are the min/max values of a range of uids to include 

params (dictionary) - Key-value pair of filters for this search. Can be one of the following: name, ipAddress, deviceClass, or productionState 

sort (string) - Key on which to sort the return result 

dir (string) - Sort order; can be either 'ASC' or 'DESC' 

=back

=over

=item REQUIRED ARGUMENTS

uids

priority

hashcheck

=back

=over

=item DEFAULT ARGUMENTS

{sort => 'name', dir => 'ASC'}

=back

=over

=item RETURNS

Success or failure message

=back

=head2 $obj->device_setCollector()

Set device(s) collector.

=over

=item ARGUMENTS

uids ([string]) - List of device uids to set

collector (string) - Collector to set devices to

hashcheck (string) - Hashcheck for the devices (from getDevices())

uid (string) - Organizer to use when using ranges to get additional uids 

ranges ([integer]) - List of two integers that are the min/max values of a range of uids to include 

params (dictionary) - Key-value pair of filters for this search. Can be one of the following: name, ipAddress, deviceClass, or 

productionState 

sort (string) - Key on which to sort the return result 

dir (string) - Sort order; can be either 'ASC' or 'DESC' 

=back

=over

=item REQUIRED ARGUMENTS

uids

collector

hashcheck

=back

=over

=item DEFAULT ARGUMENTS

{sort => 'name', dir => 'ASC'}

=back

=over

=item RETURNS

Success or failure message

=back

=head2 $obj->device_setComponentsMonitored()

Set the monitoring flag for component(s)

=over

=item ARGUMENTS

uids ([string]) - List of component uids to set

hashcheck (string) - Hashcheck for the components (from getComponents())

monitor (boolean) - True to monitor component 

uid (string) - Device to use when using ranges to get additional uids 

ranges ([integer]) - List of two integers that are the min/max values of a range of uids to include 

meta_type (string) - The meta type of the components to retrieve 

start (integer) - Offset to return the results from; used in pagination 

limit (integer) - Number of items to return; used in pagination 

sort (string) - Key on which to sort the return result 

dir (string) - Sort order; can be either 'ASC' or 'DESC' 

name (string) - Component name to search for when loading ranges 

=back

=over

=item REQUIRED ARGUMENTS

uids

hashcheck

=back

=over

=item DEFAULT ARGUMENTS

{monitor => JSON::false, start => 0, limit => 50, sort => 'name', dir => 'ASC'}

=back

=over

=item RETURNS

Success or failure message

=back

=head2 $obj->device_lockComponents()

Lock component(s) from changes.

=over

=item ARGUMENTS

uids ([string]) - List of component uids to lock

hashcheck (string) - Hashcheck for the components (from getComponents())

uid (string) - Device to use when using ranges to get additional uids 

ranges ([integer]) - List of two integers that are the min/max values of a range of uids to include 

updates (boolean) - True to lock component from updates 

deletion (boolean) - True to lock component from deletion 

sendEvent (boolean) - True to send an event when an action is blocked by locking 

meta_type (string) - The meta type of the components to retrieve 

start (integer) - Offset to return the results from; used in pagination 

limit (integer) - Number of items to return; used in pagination 

sort (string) - Key on which to sort the return result 

dir (string) - Sort order; can be either 'ASC' or 'DESC' 

name (string) - Component name to search for when loading ranges 

=back

=over

=item REQUIRED ARGUMENTS

uids

hashcheck

=back

=over

=item DEFAULT ARGUMENTS

{updates => JSON::false, deletion => JSON::false, sendEvent => JSON::false, start => 0, limit => 50, sort => 'name', dir => 'ASC'}

=back

=over

=item RETURNS

Success or failure message

=back

=head2 $obj->device_deleteComponents()

Delete device component(s).

=over

=item ARGUMENTS

uids ([string]) - List of component uids to delete

hashcheck (string) - Hashcheck for the components (from getComponents())

uid (string) - Device to use when using ranges to get additional uids 

ranges ([integer]) - List of two integers that are the min/max values of a range of uids to include 

meta_type (string) - The meta type of the components to retrieve

start (integer) - Offset to return the results from; used in pagination 

limit (integer) - Number of items to return; used in pagination 

sort (string) - Key on which to sort the return result 

dir (string) - Sort order; can be either 'ASC' or 'DESC' 

name (string) - Component name to search for when loading ranges 

=back

=over

=item REQUIRED ARGUMENTS

uids

hashcheck

=back

=over

=item DEFAULT ARGUMENTS

{start => 0, limit => 50, sort => 'name', dir => 'ASC'}

=back

=over

=item RETURNS

Success or failure message

=back

=head2 $obj->device_removeDevices()

Remove/delete device(s).

=over

=item ARGUMENTS

uids ([string]) - List of device uids to remove

hashcheck (string) - Hashcheck for the devices (from getDevices())

action (string) - Action to take. 'remove' to remove devices from organizer uid, and 'delete' to delete the device from Zenoss.

uid (string) - Organizer to use when using ranges to get additional uids and/or to remove device 

ranges ([integer]) - List of two integers that are the min/max values of a range of uids to include 

params (dictionary) - Key-value pair of filters for this search. Can be one of the following: name, ipAddress, deviceClass, or productionState 

sort (string) - Key on which to sort the return result 

dir (string) - Sort order; can be either 'ASC' or 'DESC' 

=back

=over

=item REQUIRED ARGUMENTS

uids

hashcheck

=back

=over

=item DEFAULT ARGUMENTS

{action => 'remove', sort => 'name', dir => 'ASC'}

=back

=over

=item RETURNS

devtree: ([dictionary]) Object representing the new device tree

grptree: ([dictionary]) Object representing the new group tree

systree: ([dictionary]) Object representing the new system tree

loctree: ([dictionary]) Object representing the new location tree

=back

=head2 $obj->device_getEvents()

Get events for a device.

=over

=item ARGUMENTS

uid ([string]) - Device to get events for

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

data: ([dictionary]) List of events for a device

=back

=head2 $obj->device_loadRanges()

Get a range of device uids.

=over

=item ARGUMENTS

ranges ([integer]) - List of two integers that are the min/max values of a range of uids

hashcheck (string) - Hashcheck for the devices (from getDevices())

uid (string) - Organizer to use to get uids 

params (dictionary) - Key-value pair of filters for this search. Can be one of the following: name, ipAddress, deviceClass, or productionState 

sort (string) - Key on which to sort the return result 

dir (string) - Sort order; can be either 'ASC' or 'DESC' 

=back

=over

=item REQUIRED ARGUMENTS

ranges

hashcheck

=back

=over

=item DEFAULT ARGUMENTS

{sort => 'name', dir => 'ASC'}

=back

=over

=item RETURNS

A list of device uids

=back

=head2 $obj->device_loadComponentRanges()

Get a range of component uids.

=over

=item ARGUMENTS

ranges ([integer]) - List of two integers that are the min/max values of a range of uids

hashcheck (string) - not used

uid (string) - Device to use to get uids

types ([string]) - The types of components to retrieve 

meta_type (string) - The meta type of the components to retrieve 

start (integer) - Offset to return the results from; used in pagination 

limit (integer) - Number of items to return; used in pagination 

sort (string) - Key on which to sort the return result 

dir (string) - Sort order; can be either 'ASC' or 'DESC' 

name (string) - Component name to search for when loading ranges 

=back

=over

=item REQUIRED ARGUMENTS

ranges

hashcheck

=back

=over

=item DEFAULT ARGUMENTS

{start => 0, sort => 'name', dir => 'ASC'}

=back

=over

=item RETURNS

A list of component uids

=back

=head2 $obj->device_getUserCommands()

Get a list of user commands for a device uid.

=over

=item ARGUMENTS

uid (string) - Device to use to get user commands

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

List of objects representing user commands

=back

=head2 $obj->device_getProductionStates()

Get a list of available production states.

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

List of name/value pairs of available production states

=back

=head2 $obj->device_getPriorities()

Get a list of available device priorities.

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

List of name/value pairs of available device priorities

=back

=head2 $obj->device_getCollectors()

Get a list of available collectors.

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

List of collectors

=back

=head2 $obj->device_getDeviceClasses()

Get a list of all device classes.

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

deviceClasses: ([dictionary]) List of device classes

totalCount: (integer) Total number of device classes

=back

=head2 $obj->device_getManufacturerNames()

Get a list of all manufacturer names.

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

manufacturers: ([dictionary]) List of manufacturer names

totalCount: (integer) Total number of manufacturer names

=back

=head2 $obj->device_getHardwareProductNames()

Get a list of all hardware product names from a manufacturer.

=over

=item ARGUMENTS

manufacturer (string) - Manufacturer name

=back

=over

=item REQUIRED ARGUMENTS

N/A

=back

=over

=item DEFAULT ARGUMENTS

{manufacturer => ''}

=back

=over

=item RETURNS

productNames: ([dictionary]) List of hardware product names

totalCount: (integer) Total number of hardware product names

=back

=head2 $obj->device_getOSProductNames()

Get a list of all OS product names from a manufacturer.

=over

=item ARGUMENTS

manufacturer (string) - Manufacturer name

=back

=over

=item REQUIRED ARGUMENTS

N/A

=back

=over

=item DEFAULT ARGUMENTS

{manufacturer => ''}

=back

=over

=item RETURNS

productNames: ([dictionary]) List of OS product names

totalCount: (integer) Total number of OS product names

=back

=head2 $obj->device_addDevice()

Add a device.

=over

=item ARGUMENTS

deviceName (string) - Name or IP of the new device

deviceClass (string) - The device class to add new device to

title (string) - The title of the new device 

snmpCommunity (string) - A specific community string to use for this device. 

snmpPort (integer) - SNMP port on new device 

model (boolean) - True to model device at add time 

collector (string) - Collector to use for new device 

rackSlot (string) - Rack slot description 

productionState (integer) - Production state of the new device 

comments (string) - Comments on this device 

hwManufacturer (string) - Hardware manufacturer name 

hwProductName (string) - Hardware product name 

osManufacturer (string) - OS manufacturer name 

osProductName (string) - OS product name 

priority (integer) - Priority of this device 

tag (string) - Tag number of this device 

serialNumber (string) - Serial number of this device 

=back

=over

=item REQUIRED ARGUMENTS

deviceName

deviceClass

=back

=over

=item DEFAULT ARGUMENTS

{snmpCommunity => '', snmpPort => '161', collector => 'localhost', rackSlot => 0, productionState => 1000, comments => '', hwManufacturer => '', hwProductName => '', osManufacturer => '', osProductName => '', priority => 3, tag => '', serialNumber => ''}

=back

=over

=item RETURNS

jobId: (string) ID of the add device job

=back

=head2 $obj->device_addLocalTemplate()

Adds a local template on a device.

=over

=item ARGUMENTS

deviceUid (string) - Device uid to have local template

templateId (string) - Name of the new template

=back

=over

=item REQUIRED ARGUMENTS

deviceUid

templateId

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

Success message

=back

=head2 $obj->device_removeLocalTemplate()

Removes a locally defined template on a device.

=over

=item ARGUMENTS

deviceUid (string) - Device uid that has local template

templateUid (string) - Name of the template to remove

=back

=over

=item REQUIRED ARGUMENTS

deviceUid

templateUid

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

Success message

=back

=head2 $obj->device_getLocalTemplates()

Get a list of locally defined templates on a device.

=over

=item ARGUMENTS

uid (string) - Device uid to query for templates

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

data: ([dictionary]) List of objects representing local templates

=back

=head2 $obj->device_getTemplates()

Get a list of available templates for a device.

=over

=item ARGUMENTS

id (string) - Device uid to query for templates

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

data: ([dictionary]) List of objects representing templates

=back

=head2 $obj->device_getUnboundTemplates()

Get a list of unbound templates for a device.

=over

=item ARGUMENTS

uid (string) - Device uid to query for templates

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

data: ([dictionary]) List of objects representing templates

=back

=head2 $obj->device_getBoundTemplates()

Get a list of bound templates for a device.

=over

=item ARGUMENTS

uid (string) - Device uid to query for templates

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

data: ([dictionary]) List of objects representing templates

=back

=head2 $obj->device_setBoundTemplates()

Set a list of templates as bound to a device.

=over

=item ARGUMENTS

uid (string) - Device uid to bind templates to

templateIds ([string]) - List of template uids to bind to device

=back

=over

=item REQUIRED ARGUMENTS

uid

templateIds

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

Success message

=back

=head2 $obj->device_resetBoundTemplates()

Remove all bound templates from a device.

=over

=item ARGUMENTS

uid (string) - Device uid to remove bound templates from

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

=head2 $obj->device_bindOrUnbindTemplate()

Bind an unbound template or unbind a bound template from a device.

=over

=item ARGUMENTS

uid (string) - Device uid to bind/unbind template

templateUid (string) - Template uid to bind/unbind

=back

=over

=item REQUIRED ARGUMENTS

uid

templateUid

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

Success message

=back

=head2 $obj->device_getOverridableTemplates()

Get a list of available templates on a device that can be overridden.

=over

=item ARGUMENTS

uid (string) - Device to query for overridable templates

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

data: ([dictionary]) List of objects representing templates

=back

=head2 $obj->device_clearGeocodeCache()

Clear the Google Maps geocode cache.

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

Success message

=back

=head2 $obj->device_getGraphDefs()

Returns the url and title for each graph for the object passed in.

=over

=item ARGUMENTS

uid (string) - uid of the device

drange (unknown) - I assume this is some type of date range, but the API doesnt document how to specify.

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

data: ([dictionary]) List of objects representing urls / titles for each graph

=back

=head2 $obj->device_getGroups()

Get a list of all groups

=over

=item ARGUMENTS

N/A

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

systems: ([dictionary]) List of groups

totalCount: (integer) Total number of groups

=back

=head2 $obj->device_getLocations()

Get a list of all locations

=over

=item ARGUMENTS

N/A

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

systems: ([dictionary]) List of locations

totalCount: (integer) Total number of locations

=back

=head2 $obj->device_getModifications()

Given a uid this method returns meta data about when it was modified.

=over

=item ARGUMENTS

id (string) - uid of a device

types (dictionary) - Not sure what this really is.  Python code says it sorts by this?

=back

=over

=item REQUIRED ARGUMENTS

id

=back

=over

=item DEFAULT ARGUMENTS

{types => JSON::null}

=back

=over

=item RETURNS

data: ([dictionary]) List of device modifications

=back

=head2 $obj->device_getSystems()

Get a list of all systems

=over

=item ARGUMENTS

N/A

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

systems: ([dictionary]) List of systems

totalCount: (integer) Total number of systems

=back

=head2 $obj->device_getZenProperties()

Returns the definition and values of all the zen properties for this context

=over

=item ARGUMENTS

uid (string) - Unique identifier of the device

start (integer) - Offset to return the results from; used in pagination

params (dictionary) - Key-value pair of filters for this search

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

{start => 0, dir => 'ASC'}

=back

=over

=item RETURNS

data: ([dictionary]) List of zProperties

totalCount: (integer) Total number of properties

=back

=head2 $obj->device_getZenProperty()

Returns information about a zProperty for a given context, including its value

=over

=item ARGUMENTS

uid (string) - Unique identifier of the device

zProperty (string) - Name of the zProperty

=back

=over

=item REQUIRED ARGUMENTS

uid

zProperty

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

data: ([dictionary]) zProperty information/data

=back

=head2 $obj->device_deleteZenProperty()

Removes the local instance of the each property in properties. Note that the property will only be deleted if a hasProperty is true

=over

=item ARGUMENTS

uid (string) - Unique identifier of the device

zProperty (string) - Name of the zProperty

=back

=over

=item REQUIRED ARGUMENTS

uid

zProperty

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

data: ([dictionary]) zProperty information/data

=back

=head2 $obj->device_setZenProperty()

Sets the zProperty value

=over

=item ARGUMENTS

uid (string) - Unique identifier of the device

zProperty (string) - Name of the zProperty

value (type) - Value to set the zProperty to

=back

=over

=item REQUIRED ARGUMENTS

uid

zProperty

value

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

data: ([dictionary]) zProperty information/data response

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