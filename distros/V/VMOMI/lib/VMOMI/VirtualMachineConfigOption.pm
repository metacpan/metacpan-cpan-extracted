package VMOMI::VirtualMachineConfigOption;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['version', undef, 0, ],
    ['description', undef, 0, ],
    ['guestOSDescriptor', 'GuestOsDescriptor', 1, ],
    ['guestOSDefaultIndex', undef, 0, ],
    ['hardwareOptions', 'VirtualHardwareOption', 0, ],
    ['capabilities', 'VirtualMachineCapability', 0, ],
    ['datastore', 'DatastoreOption', 0, ],
    ['defaultDevice', 'VirtualDevice', 1, 1],
    ['supportedMonitorType', undef, 1, ],
    ['supportedOvfEnvironmentTransport', undef, 1, 1],
    ['supportedOvfInstallTransport', undef, 1, 1],
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
