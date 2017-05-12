package VMOMI::VirtualMachineConfigSummary;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['name', undef, 0, ],
    ['template', 'boolean', 0, ],
    ['vmPathName', undef, 0, ],
    ['memorySizeMB', undef, 0, 1],
    ['cpuReservation', undef, 0, 1],
    ['memoryReservation', undef, 0, 1],
    ['numCpu', undef, 0, 1],
    ['numEthernetCards', undef, 0, 1],
    ['numVirtualDisks', undef, 0, 1],
    ['uuid', undef, 0, 1],
    ['instanceUuid', undef, 0, 1],
    ['guestId', undef, 0, 1],
    ['guestFullName', undef, 0, 1],
    ['annotation', undef, 0, 1],
    ['product', 'VAppProductInfo', 0, 1],
    ['installBootRequired', 'boolean', 0, 1],
    ['ftInfo', 'FaultToleranceConfigInfo', 0, 1],
    ['managedBy', 'ManagedByInfo', 0, 1],
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
