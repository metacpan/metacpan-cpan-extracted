package VMOMI::HostLowLevelProvisioningManagerDiskLayoutSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['controllerType', undef, 0, ],
    ['busNumber', undef, 0, ],
    ['unitNumber', undef, 0, ],
    ['srcFilename', undef, 0, ],
    ['dstFilename', undef, 0, ],
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
