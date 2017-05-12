package VMOMI::CustomizationSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['options', 'CustomizationOptions', 0, 1],
    ['identity', 'CustomizationIdentitySettings', 0, ],
    ['globalIPSettings', 'CustomizationGlobalIPSettings', 0, ],
    ['nicSettingMap', 'CustomizationAdapterMapping', 1, 1],
    ['encryptionKey', undef, 1, 1],
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
