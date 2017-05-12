package VMOMI::HostGraphicsInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['deviceName', undef, 0, ],
    ['vendorName', undef, 0, ],
    ['pciId', undef, 0, ],
    ['graphicsType', undef, 0, ],
    ['memorySizeInKB', undef, 0, ],
    ['vm', 'ManagedObjectReference', 1, 1],
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
