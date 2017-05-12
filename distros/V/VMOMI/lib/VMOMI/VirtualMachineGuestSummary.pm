package VMOMI::VirtualMachineGuestSummary;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['guestId', undef, 0, 1],
    ['guestFullName', undef, 0, 1],
    ['toolsStatus', 'VirtualMachineToolsStatus', 0, 1],
    ['toolsVersionStatus', undef, 0, 1],
    ['toolsVersionStatus2', undef, 0, 1],
    ['toolsRunningStatus', undef, 0, 1],
    ['hostName', undef, 0, 1],
    ['ipAddress', undef, 0, 1],
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
