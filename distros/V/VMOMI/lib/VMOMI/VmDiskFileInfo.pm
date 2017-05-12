package VMOMI::VmDiskFileInfo;
use parent 'VMOMI::FileInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'FileInfo',
    'DynamicData',
);

our @class_members = ( 
    ['diskType', undef, 0, 1],
    ['capacityKb', undef, 0, 1],
    ['hardwareVersion', undef, 0, 1],
    ['controllerType', undef, 0, 1],
    ['diskExtents', undef, 1, 1],
    ['thin', 'boolean', 0, 1],
    ['encryption', 'VmDiskFileEncryptionInfo', 0, 1],
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
