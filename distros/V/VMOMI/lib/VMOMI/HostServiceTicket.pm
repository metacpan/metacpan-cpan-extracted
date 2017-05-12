package VMOMI::HostServiceTicket;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['host', undef, 0, 1],
    ['port', undef, 0, 1],
    ['sslThumbprint', undef, 0, 1],
    ['service', undef, 0, ],
    ['serviceVersion', undef, 0, ],
    ['sessionId', undef, 0, ],
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
