package VMOMI::VirtualDiskRawDiskMappingVer1BackingInfo;
use parent 'VMOMI::VirtualDeviceFileBackingInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualDeviceFileBackingInfo',
    'VirtualDeviceBackingInfo',
    'DynamicData',
);

our @class_members = ( 
    ['lunUuid', undef, 0, 1],
    ['deviceName', undef, 0, 1],
    ['compatibilityMode', undef, 0, 1],
    ['diskMode', undef, 0, 1],
    ['uuid', undef, 0, 1],
    ['contentId', undef, 0, 1],
    ['changeId', undef, 0, 1],
    ['parent', 'VirtualDiskRawDiskMappingVer1BackingInfo', 0, 1],
    ['sharing', undef, 0, 1],
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
