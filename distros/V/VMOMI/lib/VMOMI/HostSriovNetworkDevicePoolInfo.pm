package VMOMI::HostSriovNetworkDevicePoolInfo;
use parent 'VMOMI::HostSriovDevicePoolInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'HostSriovDevicePoolInfo',
    'DynamicData',
);

our @class_members = ( 
    ['switchKey', undef, 0, 1],
    ['switchUuid', undef, 0, 1],
    ['pnic', 'PhysicalNic', 1, 1],
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
