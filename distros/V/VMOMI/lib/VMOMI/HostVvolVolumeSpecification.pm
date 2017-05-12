package VMOMI::HostVvolVolumeSpecification;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['maxSizeInMB', undef, 0, ],
    ['volumeName', undef, 0, ],
    ['vasaProviderInfo', 'VimVasaProviderInfo', 1, 1],
    ['storageArray', 'VASAStorageArray', 1, 1],
    ['uuid', undef, 0, ],
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
