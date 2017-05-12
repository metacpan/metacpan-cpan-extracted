package VMOMI::VmFaultToleranceConfigIssue;
use parent 'VMOMI::VmFaultToleranceIssue';

use strict;
use warnings;

our @class_ancestors = ( 
    'VmFaultToleranceIssue',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['reason', undef, 0, 1],
    ['entityName', undef, 0, 1],
    ['entity', 'ManagedObjectReference', 0, 1],
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
