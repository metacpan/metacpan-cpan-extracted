package VMOMI::DatastoreFileEvent;
use parent 'VMOMI::DatastoreEvent';

use strict;
use warnings;

our @class_ancestors = ( 
    'DatastoreEvent',
    'Event',
    'DynamicData',
);

our @class_members = ( 
    ['targetFile', undef, 0, ],
    ['sourceOfOperation', undef, 0, 1],
    ['succeeded', 'boolean', 0, 1],
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
