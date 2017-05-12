package Local::Role;

use Role::Tiny;

requires qw( foo );

sub bar { 2 }

sub _baz { 3 }

1;
