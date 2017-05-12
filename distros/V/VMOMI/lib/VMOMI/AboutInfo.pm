package VMOMI::AboutInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['name', undef, 0, ],
    ['fullName', undef, 0, ],
    ['vendor', undef, 0, ],
    ['version', undef, 0, ],
    ['build', undef, 0, ],
    ['localeVersion', undef, 0, 1],
    ['localeBuild', undef, 0, 1],
    ['osType', undef, 0, ],
    ['productLineId', undef, 0, ],
    ['apiType', undef, 0, ],
    ['apiVersion', undef, 0, ],
    ['instanceUuid', undef, 0, 1],
    ['licenseProductName', undef, 0, 1],
    ['licenseProductVersion', undef, 0, 1],
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
