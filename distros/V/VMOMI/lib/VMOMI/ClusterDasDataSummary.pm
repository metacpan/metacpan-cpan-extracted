package VMOMI::ClusterDasDataSummary;
use parent 'VMOMI::ClusterDasData';

use strict;
use warnings;

our @class_ancestors = ( 
    'ClusterDasData',
    'DynamicData',
);

our @class_members = ( 
    ['hostListVersion', undef, 0, ],
    ['clusterConfigVersion', undef, 0, ],
    ['compatListVersion', undef, 0, ],
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
