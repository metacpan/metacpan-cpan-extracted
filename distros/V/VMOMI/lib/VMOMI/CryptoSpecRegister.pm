package VMOMI::CryptoSpecRegister;
use parent 'VMOMI::CryptoSpecNoOp';

use strict;
use warnings;

our @class_ancestors = ( 
    'CryptoSpecNoOp',
    'CryptoSpec',
    'DynamicData',
);

our @class_members = ( 
    ['cryptoKeyId', 'CryptoKeyId', 0, ],
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
