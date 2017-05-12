package VMOMI::ClusterUsageSummary;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['totalCpuCapacityMhz', undef, 0, ],
    ['totalMemCapacityMB', undef, 0, ],
    ['cpuReservationMhz', undef, 0, ],
    ['memReservationMB', undef, 0, ],
    ['poweredOffCpuReservationMhz', undef, 0, 1],
    ['poweredOffMemReservationMB', undef, 0, 1],
    ['cpuDemandMhz', undef, 0, ],
    ['memDemandMB', undef, 0, ],
    ['statsGenNumber', undef, 0, ],
    ['cpuEntitledMhz', undef, 0, ],
    ['memEntitledMB', undef, 0, ],
    ['poweredOffVmCount', undef, 0, ],
    ['totalVmCount', undef, 0, ],
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
