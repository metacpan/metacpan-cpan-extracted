package VMOMI::AlarmInfo;
use parent 'VMOMI::AlarmSpec';

use strict;
use warnings;

our @class_ancestors = ( 
    'AlarmSpec',
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['alarm', 'ManagedObjectReference', 0, ],
    ['entity', 'ManagedObjectReference', 0, ],
    ['lastModifiedTime', undef, 0, ],
    ['lastModifiedUser', undef, 0, ],
    ['creationEventId', undef, 0, ],
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
