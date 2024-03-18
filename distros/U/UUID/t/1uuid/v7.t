use strict;
use warnings;
use Test::More;
use MyNote;

use vars '@OPTS';

BEGIN {
    @OPTS = qw(:mac=random uuid7 parse unparse type variant);
}

use UUID @OPTS;

my $bin;
my $str = uuid7();
note '';
note $str;

ok defined($str),      'defined';
is length($str), 36,   'length';
ok !parse($str, $bin), 'parsable';

# must be v7
my $type = type($bin);
is $type, 7, 'correct type';

# all are variant 1
is variant($bin), 1, 'correct variant';

my $foo;
unparse($bin, $foo);
is $foo, $str, 'unparse';
note $foo;

done_testing;
