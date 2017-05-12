package VMOMI::VmFaultToleranceConfigIssueWrapper;
use parent 'VMOMI::VmFaultToleranceIssue';

use strict;
use warnings;

our @class_ancestors = ( 
    'VmFaultToleranceIssue',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['entityName', undef, 0, 1],
    ['entity', 'ManagedObjectReference', 0, 1],
    ['error', 'LocalizedMethodFault', 0, 1],
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
