package VMOMI::DVSNameArrayUplinkPortPolicy;
use parent 'VMOMI::DVSUplinkPortPolicy';

use strict;
use warnings;

our @class_ancestors = ( 
    'DVSUplinkPortPolicy',
    'DynamicData',
);

our @class_members = ( 
    ['uplinkPortName', undef, 1, ],
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
