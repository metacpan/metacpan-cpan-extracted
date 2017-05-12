package VMOMI::ClusterVmHostRuleInfo;
use parent 'VMOMI::ClusterRuleInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'ClusterRuleInfo',
    'DynamicData',
);

our @class_members = ( 
    ['vmGroupName', undef, 0, 1],
    ['affineHostGroupName', undef, 0, 1],
    ['antiAffineHostGroupName', undef, 0, 1],
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
