package VMOMI::WinNetBIOSConfigInfo;
use parent 'VMOMI::NetBIOSConfigInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'NetBIOSConfigInfo',
    'DynamicData',
);

our @class_members = ( 
    ['primaryWINS', undef, 0, ],
    ['secondaryWINS', undef, 0, 1],
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
