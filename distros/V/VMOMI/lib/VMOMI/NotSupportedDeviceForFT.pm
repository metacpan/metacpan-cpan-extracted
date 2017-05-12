package VMOMI::NotSupportedDeviceForFT;
use parent 'VMOMI::VmFaultToleranceIssue';

use strict;
use warnings;

our @class_ancestors = ( 
    'VmFaultToleranceIssue',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['host', 'ManagedObjectReference', 0, ],
    ['hostName', undef, 0, 1],
    ['vm', 'ManagedObjectReference', 0, ],
    ['vmName', undef, 0, 1],
    ['deviceType', undef, 0, ],
    ['deviceLabel', undef, 0, 1],
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
