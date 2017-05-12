package VMOMI::IoFilterInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['id', undef, 0, ],
    ['name', undef, 0, ],
    ['vendor', undef, 0, ],
    ['version', undef, 0, ],
    ['type', undef, 0, 1],
    ['summary', undef, 0, 1],
    ['releaseDate', undef, 0, 1],
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
