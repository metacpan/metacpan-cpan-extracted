package VMOMI::FileBackedVirtualDiskSpec;
use parent 'VMOMI::VirtualDiskSpec';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualDiskSpec',
    'DynamicData',
);

our @class_members = ( 
    ['capacityKb', undef, 0, ],
    ['profile', 'VirtualMachineProfileSpec', 1, 1],
    ['crypto', 'CryptoSpec', 0, 1],
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
