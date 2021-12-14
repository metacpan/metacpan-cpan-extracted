use strict;
use warnings;

use Test::More q//;

use FindBin qw/$Bin/;
use lib qq{$Bin/lib};
use Foo;

my $foo = Foo->new( some => q{thing} );

is ref $foo,     q{Foo::_1}, q{ref returns expected internalized package string};
is $foo->some,   q{thing},   q{value returned by top level accessor};
is $foo->boop,   q{boop},    q{value returned by predefined method package (boop)};
is $foo->beep,   q{beep},    q{value returned by predefined method package (beep)};
is $foo->bar(4), 4,          q{no error setting value with default accessor};

my $foo2 = Foo->new( some => q{thang} );

is ref $foo2,      q{Foo::_2}, q{ref returns expected internalized package string};
is $foo2->some,    q{thang},   q{value returned by top level accessor};
is $foo2->boop,    q{boop},    q{value returned by predefined method package (boop)};
is $foo2->beep,    q{beep},    q{value returned by predefined method package (beep)};
is $foo2->bar(12), 12,         q{no error setting value with default accessor};

isnt $foo2->bar, $foo->bar, q{multiple instances of Foo donut conflict};

my $foo_deeply = Foo->new_deeply( some => q{thing}, more => { other => q{things} } );
is ref $foo_deeply,          q{Foo::_3}, q{ref returns expected internalized package string};
is $foo_deeply->more->other, q{things},  q{value returned by nested hash reference provided to constructor};

done_testing;
