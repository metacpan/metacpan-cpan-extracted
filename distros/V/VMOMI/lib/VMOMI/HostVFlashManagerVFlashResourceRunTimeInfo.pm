package VMOMI::HostVFlashManagerVFlashResourceRunTimeInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['usage', undef, 0, ],
    ['capacity', undef, 0, ],
    ['accessible', 'boolean', 0, ],
    ['capacityForVmCache', undef, 0, ],
    ['freeForVmCache', undef, 0, ],
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
