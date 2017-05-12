package VMOMI::VmfsDatastoreInfo;
use parent 'VMOMI::DatastoreInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'DatastoreInfo',
    'DynamicData',
);

our @class_members = ( 
    ['maxPhysicalRDMFileSize', undef, 0, 1],
    ['maxVirtualRDMFileSize', undef, 0, 1],
    ['vmfs', 'HostVmfsVolume', 0, 1],
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
