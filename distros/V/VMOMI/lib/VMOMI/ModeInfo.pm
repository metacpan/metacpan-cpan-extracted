package VMOMI::ModeInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['browse', undef, 0, 1],
    ['read', undef, 0, ],
    ['modify', undef, 0, ],
    ['use', undef, 0, ],
    ['admin', undef, 0, 1],
    ['full', undef, 0, ],
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
