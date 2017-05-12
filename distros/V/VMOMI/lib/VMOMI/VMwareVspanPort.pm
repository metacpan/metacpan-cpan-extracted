package VMOMI::VMwareVspanPort;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['portKey', undef, 1, 1],
    ['uplinkPortName', undef, 1, 1],
    ['wildcardPortConnecteeType', undef, 1, 1],
    ['vlans', undef, 1, 1],
    ['ipAddress', undef, 1, 1],
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
