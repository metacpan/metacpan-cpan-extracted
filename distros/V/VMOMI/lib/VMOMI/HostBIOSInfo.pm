package VMOMI::HostBIOSInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['biosVersion', undef, 0, 1],
    ['releaseDate', undef, 0, 1],
    ['vendor', undef, 0, 1],
    ['majorRelease', undef, 0, 1],
    ['minorRelease', undef, 0, 1],
    ['firmwareMajorRelease', undef, 0, 1],
    ['firmwareMinorRelease', undef, 0, 1],
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
