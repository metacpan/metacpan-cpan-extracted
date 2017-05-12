package VMOMI::HostNicTeamingPolicy;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['policy', undef, 0, 1],
    ['reversePolicy', 'boolean', 0, 1],
    ['notifySwitches', 'boolean', 0, 1],
    ['rollingOrder', 'boolean', 0, 1],
    ['failureCriteria', 'HostNicFailureCriteria', 0, 1],
    ['nicOrder', 'HostNicOrderPolicy', 0, 1],
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
