package VMOMI::DiagnosticManagerLogDescriptor;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['fileName', undef, 0, ],
    ['creator', undef, 0, ],
    ['format', undef, 0, ],
    ['mimeType', undef, 0, ],
    ['info', 'Description', 0, ],
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
