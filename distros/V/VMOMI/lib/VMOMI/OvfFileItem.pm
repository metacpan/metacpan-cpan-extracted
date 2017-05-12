package VMOMI::OvfFileItem;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['deviceId', undef, 0, ],
    ['path', undef, 0, ],
    ['compressionMethod', undef, 0, 1],
    ['chunkSize', undef, 0, 1],
    ['size', undef, 0, 1],
    ['cimType', undef, 0, ],
    ['create', 'boolean', 0, ],
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
