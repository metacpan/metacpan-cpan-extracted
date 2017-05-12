package VMOMI::CustomizationLinuxPrep;
use parent 'VMOMI::CustomizationIdentitySettings';

use strict;
use warnings;

our @class_ancestors = ( 
    'CustomizationIdentitySettings',
    'DynamicData',
);

our @class_members = ( 
    ['hostName', 'CustomizationName', 0, ],
    ['domain', undef, 0, ],
    ['timeZone', undef, 0, 1],
    ['hwClockUTC', 'boolean', 0, 1],
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
