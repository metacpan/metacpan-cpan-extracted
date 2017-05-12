package Local::DirectImpl;

use Class::Tiny qw( foo );
use Role::Tiny::With;

with qw( Local::Role );

1;
