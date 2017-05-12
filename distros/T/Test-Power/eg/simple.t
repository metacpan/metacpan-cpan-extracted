use strict;
use warnings;
use utf8;
use Test::More;
use Test::Power;

sub foo { 5 }
sub bar { 5,4,3 }
{
    package Foo;
    sub new { bless {}, shift }
    sub wow { $_[0] * 2 }
}
expect { foo() == 3 };
expect { bar() == 3 };
expect { my $foo = Foo->new(); $foo->wow(3) == 6 };

expect { die };

done_testing;

