package VMOMI::KmipServerInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['name', undef, 0, ],
    ['address', undef, 0, ],
    ['port', undef, 0, ],
    ['proxyAddress', undef, 0, 1],
    ['proxyPort', undef, 0, 1],
    ['reconnect', undef, 0, 1],
    ['protocol', undef, 0, 1],
    ['nbio', undef, 0, 1],
    ['timeout', undef, 0, 1],
    ['userName', undef, 0, 1],
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
