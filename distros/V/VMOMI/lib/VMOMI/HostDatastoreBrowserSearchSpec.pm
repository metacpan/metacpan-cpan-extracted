package VMOMI::HostDatastoreBrowserSearchSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['query', 'FileQuery', 1, 1],
    ['details', 'FileQueryFlags', 0, 1],
    ['searchCaseInsensitive', 'boolean', 0, 1],
    ['matchPattern', undef, 1, 1],
    ['sortFoldersFirst', 'boolean', 0, 1],
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
