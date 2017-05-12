package VMOMI::HostCpuIdInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['level', undef, 0, ],
    ['vendor', undef, 0, 1],
    ['eax', undef, 0, 1],
    ['ebx', undef, 0, 1],
    ['ecx', undef, 0, 1],
    ['edx', undef, 0, 1],
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
