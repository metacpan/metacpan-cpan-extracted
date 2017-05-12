package VMOMI::TaskInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['task', 'ManagedObjectReference', 0, ],
    ['description', 'LocalizableMessage', 0, 1],
    ['name', undef, 0, 1],
    ['descriptionId', undef, 0, ],
    ['entity', 'ManagedObjectReference', 0, 1],
    ['entityName', undef, 0, 1],
    ['locked', 'ManagedObjectReference', 1, 1],
    ['state', 'TaskInfoState', 0, ],
    ['cancelled', 'boolean', 0, ],
    ['cancelable', 'boolean', 0, ],
    ['error', 'LocalizedMethodFault', 0, 1],
    ['result', 'anyType', 0, 1],
    ['progress', undef, 0, 1],
    ['reason', 'TaskReason', 0, ],
    ['queueTime', undef, 0, ],
    ['startTime', undef, 0, 1],
    ['completeTime', undef, 0, 1],
    ['eventChainId', undef, 0, ],
    ['changeTag', undef, 0, 1],
    ['parentTaskKey', undef, 0, 1],
    ['rootTaskKey', undef, 0, 1],
    ['activationId', undef, 0, 1],
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
