use strict;
use Test::More tests => 2;

use lib qw(t/lib);
no capitalization qw(Module::LikeJava);

my $m = Module::LikeJava->new;
can_ok $m, qw(fooAndBar   BarAndBAZ   _Bar FOO FOObar);
can_ok $m, qw(foo_and_bar bar_and_baz _bar foo foobar);


