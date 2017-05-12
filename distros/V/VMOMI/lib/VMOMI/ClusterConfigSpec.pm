package VMOMI::ClusterConfigSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['dasConfig', 'ClusterDasConfigInfo', 0, 1],
    ['dasVmConfigSpec', 'ClusterDasVmConfigSpec', 1, 1],
    ['drsConfig', 'ClusterDrsConfigInfo', 0, 1],
    ['drsVmConfigSpec', 'ClusterDrsVmConfigSpec', 1, 1],
    ['rulesSpec', 'ClusterRuleSpec', 1, 1],
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
