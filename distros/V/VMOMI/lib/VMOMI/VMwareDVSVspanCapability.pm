package VMOMI::VMwareDVSVspanCapability;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['mixedDestSupported', 'boolean', 0, ],
    ['dvportSupported', 'boolean', 0, ],
    ['remoteSourceSupported', 'boolean', 0, ],
    ['remoteDestSupported', 'boolean', 0, ],
    ['encapRemoteSourceSupported', 'boolean', 0, ],
    ['erspanProtocolSupported', 'boolean', 0, 1],
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
