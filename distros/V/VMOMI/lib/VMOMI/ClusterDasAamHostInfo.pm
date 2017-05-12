package VMOMI::ClusterDasAamHostInfo;
use parent 'VMOMI::ClusterDasHostInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'ClusterDasHostInfo',
    'DynamicData',
);

our @class_members = ( 
    ['hostDasState', 'ClusterDasAamNodeState', 1, 1],
    ['primaryHosts', undef, 1, 1],
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
