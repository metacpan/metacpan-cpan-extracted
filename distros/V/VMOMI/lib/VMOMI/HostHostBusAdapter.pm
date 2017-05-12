package VMOMI::HostHostBusAdapter;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, 1],
    ['device', undef, 0, ],
    ['bus', undef, 0, ],
    ['status', undef, 0, ],
    ['model', undef, 0, ],
    ['driver', undef, 0, 1],
    ['pci', undef, 0, 1],
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
