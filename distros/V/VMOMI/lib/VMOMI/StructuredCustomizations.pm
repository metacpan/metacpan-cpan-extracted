package VMOMI::StructuredCustomizations;
use parent 'VMOMI::HostProfilesEntityCustomizations';

use strict;
use warnings;

our @class_ancestors = ( 
    'HostProfilesEntityCustomizations',
    'DynamicData',
);

our @class_members = ( 
    ['entity', 'ManagedObjectReference', 0, ],
    ['customizations', 'AnswerFile', 0, 1],
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
