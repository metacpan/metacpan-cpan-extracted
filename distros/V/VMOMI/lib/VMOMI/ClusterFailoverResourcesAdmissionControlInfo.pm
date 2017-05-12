package VMOMI::ClusterFailoverResourcesAdmissionControlInfo;
use parent 'VMOMI::ClusterDasAdmissionControlInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'ClusterDasAdmissionControlInfo',
    'DynamicData',
);

our @class_members = ( 
    ['currentCpuFailoverResourcesPercent', undef, 0, ],
    ['currentMemoryFailoverResourcesPercent', undef, 0, ],
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
