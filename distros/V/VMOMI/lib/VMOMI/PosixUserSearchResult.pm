package VMOMI::PosixUserSearchResult;
use parent 'VMOMI::UserSearchResult';

use strict;
use warnings;

our @class_ancestors = ( 
    'UserSearchResult',
    'DynamicData',
);

our @class_members = ( 
    ['id', undef, 0, ],
    ['shellAccess', 'boolean', 0, 1],
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
