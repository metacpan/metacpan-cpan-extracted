package VMOMI::UserInputRequiredParameterMetadata;
use parent 'VMOMI::ProfilePolicyOptionMetadata';

use strict;
use warnings;

our @class_ancestors = ( 
    'ProfilePolicyOptionMetadata',
    'DynamicData',
);

our @class_members = ( 
    ['userInputParameter', 'ProfileParameterMetadata', 1, 1],
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
