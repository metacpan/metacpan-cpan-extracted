package VMOMI::HostPciDevice;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['id', undef, 0, ],
    ['classId', undef, 0, ],
    ['bus', undef, 0, ],
    ['slot', undef, 0, ],
    ['function', undef, 0, ],
    ['vendorId', undef, 0, ],
    ['subVendorId', undef, 0, ],
    ['vendorName', undef, 0, ],
    ['deviceId', undef, 0, ],
    ['subDeviceId', undef, 0, ],
    ['parentBridge', undef, 0, 1],
    ['deviceName', undef, 0, ],
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
