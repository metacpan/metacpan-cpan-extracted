package VMOMI::SoftwarePackage;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['name', undef, 0, ],
    ['version', undef, 0, ],
    ['type', undef, 0, ],
    ['vendor', undef, 0, ],
    ['acceptanceLevel', undef, 0, ],
    ['summary', undef, 0, ],
    ['description', undef, 0, ],
    ['referenceURL', undef, 1, 1],
    ['creationDate', undef, 0, 1],
    ['depends', 'Relation', 1, 1],
    ['conflicts', 'Relation', 1, 1],
    ['replaces', 'Relation', 1, 1],
    ['provides', undef, 1, 1],
    ['maintenanceModeRequired', 'boolean', 0, 1],
    ['hardwarePlatformsRequired', undef, 1, 1],
    ['capability', 'SoftwarePackageCapability', 0, ],
    ['tag', undef, 1, 1],
    ['payload', undef, 1, 1],
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
