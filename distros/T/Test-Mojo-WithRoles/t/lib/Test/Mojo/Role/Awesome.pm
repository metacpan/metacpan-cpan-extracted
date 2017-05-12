package Test::Mojo::Role::Awesome;

use Role::Tiny;
use Test::More ();

sub is_awesome { Test::More::ok 1, 'yep, awesome' }

1;

