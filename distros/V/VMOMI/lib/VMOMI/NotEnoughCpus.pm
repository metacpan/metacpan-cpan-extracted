package VMOMI::NotEnoughCpus;
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
    ['numCpuDest', undef, 0, ],
    ['numCpuVm', undef, 0, ],
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
