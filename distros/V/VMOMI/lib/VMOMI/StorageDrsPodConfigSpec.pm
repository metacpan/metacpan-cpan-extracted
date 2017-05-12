package VMOMI::StorageDrsPodConfigSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['enabled', 'boolean', 0, 1],
    ['ioLoadBalanceEnabled', 'boolean', 0, 1],
    ['defaultVmBehavior', undef, 0, 1],
    ['loadBalanceInterval', undef, 0, 1],
    ['defaultIntraVmAffinity', 'boolean', 0, 1],
    ['spaceLoadBalanceConfig', 'StorageDrsSpaceLoadBalanceConfig', 0, 1],
    ['ioLoadBalanceConfig', 'StorageDrsIoLoadBalanceConfig', 0, 1],
    ['automationOverrides', 'StorageDrsAutomationConfig', 0, 1],
    ['rule', 'ClusterRuleSpec', 1, 1],
    ['option', 'StorageDrsOptionSpec', 1, 1],
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
