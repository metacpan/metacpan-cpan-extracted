package VMOMI::ClusterDasFailoverLevelAdvancedRuntimeInfo;
use parent 'VMOMI::ClusterDasAdvancedRuntimeInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'ClusterDasAdvancedRuntimeInfo',
    'DynamicData',
);

our @class_members = ( 
    ['slotInfo', 'ClusterDasFailoverLevelAdvancedRuntimeInfoSlotInfo', 0, ],
    ['totalSlots', undef, 0, ],
    ['usedSlots', undef, 0, ],
    ['unreservedSlots', undef, 0, ],
    ['totalVms', undef, 0, ],
    ['totalHosts', undef, 0, ],
    ['totalGoodHosts', undef, 0, ],
    ['hostSlots', 'ClusterDasFailoverLevelAdvancedRuntimeInfoHostSlots', 1, 1],
    ['vmsRequiringMultipleSlots', 'ClusterDasFailoverLevelAdvancedRuntimeInfoVmSlots', 1, 1],
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
