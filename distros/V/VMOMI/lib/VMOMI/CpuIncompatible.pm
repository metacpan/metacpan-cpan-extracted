package VMOMI::CpuIncompatible;
use parent 'VMOMI::VirtualHardwareCompatibilityIssue';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualHardwareCompatibilityIssue',
    'VmConfigFault',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['level', undef, 0, ],
    ['registerName', undef, 0, ],
    ['registerBits', undef, 0, 1],
    ['desiredBits', undef, 0, 1],
    ['host', 'ManagedObjectReference', 0, 1],
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
