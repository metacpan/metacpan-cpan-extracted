package VMOMI::VirtualEthernetCard;
use parent 'VMOMI::VirtualDevice';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualDevice',
    'DynamicData',
);

our @class_members = ( 
    ['addressType', undef, 0, 1],
    ['macAddress', undef, 0, 1],
    ['wakeOnLanEnabled', 'boolean', 0, 1],
    ['resourceAllocation', 'VirtualEthernetCardResourceAllocation', 0, 1],
    ['externalId', undef, 0, 1],
    ['uptCompatibilityEnabled', 'boolean', 0, 1],
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
