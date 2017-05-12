package VMOMI::VirtualSCSIControllerOption;
use parent 'VMOMI::VirtualControllerOption';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualControllerOption',
    'VirtualDeviceOption',
    'DynamicData',
);

our @class_members = ( 
    ['numSCSIDisks', 'IntOption', 0, ],
    ['numSCSICdroms', 'IntOption', 0, ],
    ['numSCSIPassthrough', 'IntOption', 0, ],
    ['sharing', 'VirtualSCSISharing', 1, ],
    ['defaultSharedIndex', undef, 0, ],
    ['hotAddRemove', 'BoolOption', 0, ],
    ['scsiCtlrUnitNumber', undef, 0, ],
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
