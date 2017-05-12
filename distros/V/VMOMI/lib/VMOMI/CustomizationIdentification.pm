package VMOMI::CustomizationIdentification;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['joinWorkgroup', undef, 0, 1],
    ['joinDomain', undef, 0, 1],
    ['domainAdmin', undef, 0, 1],
    ['domainAdminPassword', 'CustomizationPassword', 0, 1],
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
