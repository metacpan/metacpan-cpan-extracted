package VMOMI::UserSession;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['userName', undef, 0, ],
    ['fullName', undef, 0, ],
    ['loginTime', undef, 0, ],
    ['lastActiveTime', undef, 0, ],
    ['locale', undef, 0, ],
    ['messageLocale', undef, 0, ],
    ['extensionSession', 'boolean', 0, 1],
    ['ipAddress', undef, 0, 1],
    ['userAgent', undef, 0, 1],
    ['callCount', undef, 0, 1],
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
