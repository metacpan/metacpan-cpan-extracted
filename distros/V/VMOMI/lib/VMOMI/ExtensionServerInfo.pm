package VMOMI::ExtensionServerInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['url', undef, 0, ],
    ['description', 'Description', 0, ],
    ['company', undef, 0, ],
    ['type', undef, 0, ],
    ['adminEmail', undef, 1, ],
    ['serverThumbprint', undef, 0, 1],
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
