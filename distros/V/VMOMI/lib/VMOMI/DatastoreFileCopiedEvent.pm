package VMOMI::DatastoreFileCopiedEvent;
use parent 'VMOMI::DatastoreFileEvent';

use strict;
use warnings;

our @class_ancestors = ( 
    'DatastoreFileEvent',
    'DatastoreEvent',
    'Event',
    'DynamicData',
);

our @class_members = ( 
    ['sourceDatastore', 'DatastoreEventArgument', 0, ],
    ['sourceFile', undef, 0, ],
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
