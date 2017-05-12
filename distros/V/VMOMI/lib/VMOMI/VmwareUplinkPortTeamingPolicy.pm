package VMOMI::VmwareUplinkPortTeamingPolicy;
use parent 'VMOMI::InheritablePolicy';

use strict;
use warnings;

our @class_ancestors = ( 
    'InheritablePolicy',
    'DynamicData',
);

our @class_members = ( 
    ['policy', 'StringPolicy', 0, 1],
    ['reversePolicy', 'BoolPolicy', 0, 1],
    ['notifySwitches', 'BoolPolicy', 0, 1],
    ['rollingOrder', 'BoolPolicy', 0, 1],
    ['failureCriteria', 'DVSFailureCriteria', 0, 1],
    ['uplinkPortOrder', 'VMwareUplinkPortOrderPolicy', 0, 1],
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
