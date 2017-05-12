package VMOMI::VmPodConfigForPlacement;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['storagePod', 'ManagedObjectReference', 0, ],
    ['disk', 'PodDiskLocator', 1, 1],
    ['vmConfig', 'StorageDrsVmConfigInfo', 0, 1],
    ['interVmRule', 'ClusterRuleInfo', 1, 1],
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
