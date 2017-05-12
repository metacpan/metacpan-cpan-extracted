package VMOMI::OvfCreateImportSpecResult;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['importSpec', 'ImportSpec', 0, 1],
    ['fileItem', 'OvfFileItem', 1, 1],
    ['warning', 'LocalizedMethodFault', 1, 1],
    ['error', 'LocalizedMethodFault', 1, 1],
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
