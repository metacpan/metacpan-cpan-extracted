package VMOMI::VsanHostDiskResult;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['disk', 'HostScsiDisk', 0, ],
    ['state', undef, 0, ],
    ['vsanUuid', undef, 0, 1],
    ['error', 'LocalizedMethodFault', 0, 1],
    ['degraded', 'boolean', 0, 1],
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
