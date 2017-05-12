package VMOMI::DistributedVirtualSwitchHostMember;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['runtimeState', 'DistributedVirtualSwitchHostMemberRuntimeState', 0, 1],
    ['config', 'DistributedVirtualSwitchHostMemberConfigInfo', 0, ],
    ['productInfo', 'DistributedVirtualSwitchProductSpec', 0, 1],
    ['uplinkPortKey', undef, 1, 1],
    ['status', undef, 0, ],
    ['statusDetail', undef, 0, 1],
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
