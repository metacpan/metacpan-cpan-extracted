package VMOMI::SSPIAuthentication;
use parent 'VMOMI::GuestAuthentication';

use strict;
use warnings;

our @class_ancestors = ( 
    'GuestAuthentication',
    'DynamicData',
);

our @class_members = ( 
    ['sspiToken', undef, 0, ],
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
