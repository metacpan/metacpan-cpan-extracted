package VMOMI::GuestProcessInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['name', undef, 0, ],
    ['pid', undef, 0, ],
    ['owner', undef, 0, ],
    ['cmdLine', undef, 0, ],
    ['startTime', undef, 0, ],
    ['endTime', undef, 0, 1],
    ['exitCode', undef, 0, 1],
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
