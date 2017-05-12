package VMOMI::HostTpmAttestationReport;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['tpmPcrValues', 'HostTpmDigestInfo', 1, ],
    ['tpmEvents', 'HostTpmEventLogEntry', 1, ],
    ['tpmLogReliable', 'boolean', 0, ],
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
