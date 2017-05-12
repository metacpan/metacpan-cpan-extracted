package VMOMI::FileInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['path', undef, 0, ],
    ['friendlyName', undef, 0, 1],
    ['fileSize', undef, 0, 1],
    ['modification', undef, 0, 1],
    ['owner', undef, 0, 1],
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
