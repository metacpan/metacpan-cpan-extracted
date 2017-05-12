package VMOMI::CustomizationSysprep;
use parent 'VMOMI::CustomizationIdentitySettings';

use strict;
use warnings;

our @class_ancestors = ( 
    'CustomizationIdentitySettings',
    'DynamicData',
);

our @class_members = ( 
    ['guiUnattended', 'CustomizationGuiUnattended', 0, ],
    ['userData', 'CustomizationUserData', 0, ],
    ['guiRunOnce', 'CustomizationGuiRunOnce', 0, 1],
    ['identification', 'CustomizationIdentification', 0, ],
    ['licenseFilePrintData', 'CustomizationLicenseFilePrintData', 0, 1],
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
