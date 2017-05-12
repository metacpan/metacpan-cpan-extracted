package VMOMI::BaseConfigInfoFileBackingInfo;
use parent 'VMOMI::BaseConfigInfoBackingInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'BaseConfigInfoBackingInfo',
    'DynamicData',
);

our @class_members = ( 
    ['filePath', undef, 0, ],
    ['backingObjectId', undef, 0, 1],
    ['parent', 'BaseConfigInfoFileBackingInfo', 0, 1],
    ['deltaSizeInMB', undef, 0, 1],
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
