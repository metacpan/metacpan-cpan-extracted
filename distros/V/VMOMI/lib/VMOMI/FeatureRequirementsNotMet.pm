package VMOMI::FeatureRequirementsNotMet;
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
    ['featureRequirement', 'VirtualMachineFeatureRequirement', 1, 1],
    ['vm', 'ManagedObjectReference', 0, 1],
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
