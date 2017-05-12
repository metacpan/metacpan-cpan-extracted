package VMOMI::VirtualAppImportSpec;
use parent 'VMOMI::ImportSpec';

use strict;
use warnings;

our @class_ancestors = ( 
    'ImportSpec',
    'DynamicData',
);

our @class_members = ( 
    ['name', undef, 0, ],
    ['vAppConfigSpec', 'VAppConfigSpec', 0, ],
    ['resourcePoolSpec', 'ResourceConfigSpec', 0, ],
    ['child', 'ImportSpec', 1, 1],
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
