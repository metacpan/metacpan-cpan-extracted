package VMOMI::SessionManager;
use parent 'VMOMI::ManagedObject';

use strict;
use warnings;

our @class_ancestors = (
    'ManagedObject',
);

our @class_members = (
    ['currentSession', 'UserSession', 0, 0],
    ['defaultLocale', undef, 0, 1],
    ['message', undef, 0, 0],
    ['messageLocaleList', undef, 1, 0],
    ['sessionList', 'UserSession', 1, 0],
    ['supportedLocaleList', undef, 1, 0],
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