package VMOMI::HostMultipathInfoLogicalUnit;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['id', undef, 0, ],
    ['lun', undef, 0, ],
    ['path', 'HostMultipathInfoPath', 1, ],
    ['policy', 'HostMultipathInfoLogicalUnitPolicy', 0, ],
    ['storageArrayTypePolicy', 'HostMultipathInfoLogicalUnitStorageArrayTypePolicy', 0, 1],
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
