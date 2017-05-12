package VMOMI::OvfMappedOsId;
use parent 'VMOMI::OvfImport';

use strict;
use warnings;

our @class_ancestors = ( 
    'OvfImport',
    'OvfFault',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['ovfId', undef, 0, ],
    ['ovfDescription', undef, 0, ],
    ['targetDescription', undef, 0, ],
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
