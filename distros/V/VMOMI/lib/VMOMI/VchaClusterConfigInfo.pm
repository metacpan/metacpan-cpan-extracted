package VMOMI::VchaClusterConfigInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['failoverNodeInfo1', 'FailoverNodeInfo', 0, 1],
    ['failoverNodeInfo2', 'FailoverNodeInfo', 0, 1],
    ['witnessNodeInfo', 'WitnessNodeInfo', 0, 1],
    ['state', undef, 0, ],
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
