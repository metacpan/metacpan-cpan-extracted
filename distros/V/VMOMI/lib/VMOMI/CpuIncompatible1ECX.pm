package VMOMI::CpuIncompatible1ECX;
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
    ['sse3', 'boolean', 0, ],
    ['pclmulqdq', 'boolean', 0, 1],
    ['ssse3', 'boolean', 0, ],
    ['sse41', 'boolean', 0, ],
    ['sse42', 'boolean', 0, ],
    ['aes', 'boolean', 0, 1],
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
