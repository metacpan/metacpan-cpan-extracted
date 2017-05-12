package VMOMI::OvfConsumerFault;
use parent 'VMOMI::OvfConsumerCallbackFault';

use strict;
use warnings;

our @class_ancestors = ( 
    'OvfConsumerCallbackFault',
    'OvfFault',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['errorKey', undef, 0, ],
    ['message', undef, 0, ],
    ['params', 'KeyValue', 1, 1],
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
