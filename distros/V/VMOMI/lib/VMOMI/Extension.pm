package VMOMI::Extension;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['description', 'Description', 0, ],
    ['key', undef, 0, ],
    ['company', undef, 0, 1],
    ['type', undef, 0, 1],
    ['version', undef, 0, ],
    ['subjectName', undef, 0, 1],
    ['server', 'ExtensionServerInfo', 1, 1],
    ['client', 'ExtensionClientInfo', 1, 1],
    ['taskList', 'ExtensionTaskTypeInfo', 1, 1],
    ['eventList', 'ExtensionEventTypeInfo', 1, 1],
    ['faultList', 'ExtensionFaultTypeInfo', 1, 1],
    ['privilegeList', 'ExtensionPrivilegeInfo', 1, 1],
    ['resourceList', 'ExtensionResourceInfo', 1, 1],
    ['lastHeartbeatTime', undef, 0, ],
    ['healthInfo', 'ExtensionHealthInfo', 0, 1],
    ['ovfConsumerInfo', 'ExtensionOvfConsumerInfo', 0, 1],
    ['extendedProductInfo', 'ExtExtendedProductInfo', 0, 1],
    ['managedEntityInfo', 'ExtManagedEntityInfo', 1, 1],
    ['shownInSolutionManager', 'boolean', 0, 1],
    ['solutionManagerInfo', 'ExtSolutionManagerInfo', 0, 1],
);

sub get_class_ancestors {
    return @class_ancestors;
}

sub get_class_members {
    my $class = shift;
    my @super_members = $class->SUPER::get_class_members();
    return (@super_members, @class_members);
}

1;
