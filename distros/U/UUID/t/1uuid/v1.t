use strict;
use warnings;
use Test::More;
use MyNote;

use vars '@OPTS';

BEGIN {
    @OPTS = qw(:mac=random uuid1 parse unparse type variant);
}

use UUID @OPTS;

my $bin;
my $str = uuid1();
note '';
note $str;

ok defined($str),      'defined';
ok length($str) == 36, 'length';
ok !parse($str, $bin), 'parsable';

# must be v1
my $type = type($bin);
is $type, 1, 'correct type';

# all are variant 1
is variant($bin), 1, 'correct variant';

my $foo;
unparse($bin, $foo);
is $foo, $str, 'unparse';
note $foo;

done_testing;
