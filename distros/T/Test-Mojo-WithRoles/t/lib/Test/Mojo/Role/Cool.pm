package Test::Mojo::Role::Cool;

use Role::Tiny;
use Test::More ();

sub is_cool { Test::More::ok 1, 'yep, cool' }

1;

