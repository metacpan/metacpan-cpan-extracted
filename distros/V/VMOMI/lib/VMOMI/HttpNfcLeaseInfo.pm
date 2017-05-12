package VMOMI::HttpNfcLeaseInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['lease', 'ManagedObjectReference', 0, ],
    ['entity', 'ManagedObjectReference', 0, ],
    ['deviceUrl', 'HttpNfcLeaseDeviceUrl', 1, 1],
    ['totalDiskCapacityInKB', undef, 0, ],
    ['leaseTimeout', undef, 0, ],
    ['hostMap', 'HttpNfcLeaseDatastoreLeaseInfo', 1, 1],
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
