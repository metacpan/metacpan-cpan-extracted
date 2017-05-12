package VMOMI::HostVvolVolume;
use parent 'VMOMI::HostFileSystemVolume';

use strict;
use warnings;

our @class_ancestors = ( 
    'HostFileSystemVolume',
    'DynamicData',
);

our @class_members = ( 
    ['scId', undef, 0, ],
    ['hostPE', 'VVolHostPE', 1, 1],
    ['vasaProviderInfo', 'VimVasaProviderInfo', 1, 1],
    ['storageArray', 'VASAStorageArray', 1, 1],
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
