package VMOMI::VStorageObjectConfigInfo;
use parent 'VMOMI::BaseConfigInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'BaseConfigInfo',
    'DynamicData',
);

our @class_members = ( 
    ['capacityInMB', undef, 0, ],
    ['consumptionType', undef, 1, 1],
    ['consumerId', 'ID', 1, 1],
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
