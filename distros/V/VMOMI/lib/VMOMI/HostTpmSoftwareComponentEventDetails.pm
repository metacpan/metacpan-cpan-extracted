package VMOMI::HostTpmSoftwareComponentEventDetails;
use parent 'VMOMI::HostTpmEventDetails';

use strict;
use warnings;

our @class_ancestors = ( 
    'HostTpmEventDetails',
    'DynamicData',
);

our @class_members = ( 
    ['componentName', undef, 0, ],
    ['vibName', undef, 0, ],
    ['vibVersion', undef, 0, ],
    ['vibVendor', undef, 0, ],
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
