package VMOMI::AnswerFileOptionsCreateSpec;
use parent 'VMOMI::AnswerFileCreateSpec';

use strict;
use warnings;

our @class_ancestors = ( 
    'AnswerFileCreateSpec',
    'DynamicData',
);

our @class_members = ( 
    ['userInput', 'ProfileDeferredPolicyOptionParameter', 1, 1],
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
