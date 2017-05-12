package VMOMI::HostUnresolvedVmfsVolume;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['extent', 'HostUnresolvedVmfsExtent', 1, ],
    ['vmfsLabel', undef, 0, ],
    ['vmfsUuid', undef, 0, ],
    ['totalBlocks', undef, 0, ],
    ['resolveStatus', 'HostUnresolvedVmfsVolumeResolveStatus', 0, ],
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
