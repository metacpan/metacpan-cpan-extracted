package VMOMI::VirtualResourcePoolUsage;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['vrpId', undef, 0, ],
    ['cpuReservationMhz', undef, 0, ],
    ['memReservationMB', undef, 0, ],
    ['cpuReservationUsedMhz', undef, 0, ],
    ['memReservationUsedMB', undef, 0, ],
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
