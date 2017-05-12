package VMOMI::AutoStartPowerInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', 'ManagedObjectReference', 0, ],
    ['startOrder', undef, 0, ],
    ['startDelay', undef, 0, ],
    ['waitForHeartbeat', 'AutoStartWaitHeartbeatSetting', 0, ],
    ['startAction', undef, 0, ],
    ['stopDelay', undef, 0, ],
    ['stopAction', undef, 0, ],
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
