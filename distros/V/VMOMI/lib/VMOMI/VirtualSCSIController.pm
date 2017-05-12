package VMOMI::VirtualSCSIController;
use parent 'VMOMI::VirtualController';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualController',
    'VirtualDevice',
    'DynamicData',
);

our @class_members = ( 
    ['hotAddRemove', 'boolean', 0, 1],
    ['sharedBus', 'VirtualSCSISharing', 0, ],
    ['scsiCtlrUnitNumber', undef, 0, 1],
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
