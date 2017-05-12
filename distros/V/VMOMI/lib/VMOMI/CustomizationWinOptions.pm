package VMOMI::CustomizationWinOptions;
use parent 'VMOMI::CustomizationOptions';

use strict;
use warnings;

our @class_ancestors = ( 
    'CustomizationOptions',
    'DynamicData',
);

our @class_members = ( 
    ['changeSID', 'boolean', 0, ],
    ['deleteAccounts', 'boolean', 0, ],
    ['reboot', 'CustomizationSysprepRebootOption', 0, 1],
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
