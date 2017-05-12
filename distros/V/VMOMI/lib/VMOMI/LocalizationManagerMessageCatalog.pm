package VMOMI::LocalizationManagerMessageCatalog;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['moduleName', undef, 0, ],
    ['catalogName', undef, 0, ],
    ['locale', undef, 0, ],
    ['catalogUri', undef, 0, ],
    ['lastModified', undef, 0, 1],
    ['md5sum', undef, 0, 1],
    ['version', undef, 0, 1],
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
