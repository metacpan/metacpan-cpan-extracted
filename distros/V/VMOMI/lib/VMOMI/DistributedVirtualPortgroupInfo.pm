package VMOMI::DistributedVirtualPortgroupInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['switchName', undef, 0, ],
    ['switchUuid', undef, 0, ],
    ['portgroupName', undef, 0, ],
    ['portgroupKey', undef, 0, ],
    ['portgroupType', undef, 0, ],
    ['uplinkPortgroup', 'boolean', 0, ],
    ['portgroup', 'ManagedObjectReference', 0, ],
    ['networkReservationSupported', 'boolean', 0, 1],
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
