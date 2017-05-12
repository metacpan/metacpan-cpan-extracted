package VMOMI::CpuIncompatible81EDX;
use parent 'VMOMI::CpuIncompatible';

use strict;
use warnings;

our @class_ancestors = ( 
    'CpuIncompatible',
    'VirtualHardwareCompatibilityIssue',
    'VmConfigFault',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['nx', 'boolean', 0, ],
    ['ffxsr', 'boolean', 0, ],
    ['rdtscp', 'boolean', 0, ],
    ['lm', 'boolean', 0, ],
    ['other', 'boolean', 0, ],
    ['otherOnly', 'boolean', 0, ],
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
