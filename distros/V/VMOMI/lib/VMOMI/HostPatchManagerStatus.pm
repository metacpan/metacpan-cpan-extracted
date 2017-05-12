package VMOMI::HostPatchManagerStatus;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['id', undef, 0, ],
    ['applicable', 'boolean', 0, ],
    ['reason', undef, 1, 1],
    ['integrity', undef, 0, 1],
    ['installed', 'boolean', 0, ],
    ['installState', undef, 1, 1],
    ['prerequisitePatch', 'HostPatchManagerStatusPrerequisitePatch', 1, 1],
    ['restartRequired', 'boolean', 0, ],
    ['reconnectRequired', 'boolean', 0, ],
    ['vmOffRequired', 'boolean', 0, ],
    ['supersededPatchIds', undef, 1, 1],
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
