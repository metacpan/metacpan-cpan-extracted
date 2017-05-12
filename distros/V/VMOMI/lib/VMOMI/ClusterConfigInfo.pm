package VMOMI::ClusterConfigInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['dasConfig', 'ClusterDasConfigInfo', 0, ],
    ['dasVmConfig', 'ClusterDasVmConfigInfo', 1, 1],
    ['drsConfig', 'ClusterDrsConfigInfo', 0, ],
    ['drsVmConfig', 'ClusterDrsVmConfigInfo', 1, 1],
    ['rule', 'ClusterRuleInfo', 1, 1],
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
