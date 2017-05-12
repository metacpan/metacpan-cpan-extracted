package VMOMI::VirtualSriovEthernetCard;
use parent 'VMOMI::VirtualEthernetCard';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualEthernetCard',
    'VirtualDevice',
    'DynamicData',
);

our @class_members = ( 
    ['allowGuestOSMtuChange', 'boolean', 0, 1],
    ['sriovBacking', 'VirtualSriovEthernetCardSriovBackingInfo', 0, 1],
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
