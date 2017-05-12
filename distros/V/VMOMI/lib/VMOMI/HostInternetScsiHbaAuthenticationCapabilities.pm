package VMOMI::HostInternetScsiHbaAuthenticationCapabilities;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['chapAuthSettable', 'boolean', 0, ],
    ['krb5AuthSettable', 'boolean', 0, ],
    ['srpAuthSettable', 'boolean', 0, ],
    ['spkmAuthSettable', 'boolean', 0, ],
    ['mutualChapSettable', 'boolean', 0, 1],
    ['targetChapSettable', 'boolean', 0, 1],
    ['targetMutualChapSettable', 'boolean', 0, 1],
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
