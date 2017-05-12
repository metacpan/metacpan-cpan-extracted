package VMOMI::VmDiskFileQuery;
use parent 'VMOMI::FileQuery';

use strict;
use warnings;

our @class_ancestors = ( 
    'FileQuery',
    'DynamicData',
);

our @class_members = ( 
    ['filter', 'VmDiskFileQueryFilter', 0, 1],
    ['details', 'VmDiskFileQueryFlags', 0, 1],
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
