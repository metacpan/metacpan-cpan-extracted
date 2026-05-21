use strict;
use warnings;
use MyTest;

use vars '@OPTS';

BEGIN {
    @OPTS = qw(:mac=random uuid6 parse unparse type variant);
}

use UUID @OPTS;

my $bin;
my $str = uuid6();
note '';
note $str;

ok defined($str),      'defined';
ok length($str) == 36, 'length';
ok !parse($str, $bin), 'parsable';

# must be v6
my $type = type($bin);
is $type, 6, 'correct type';

# all are variant 1
is variant($bin), 1, 'correct variant';

my $foo;
unparse($bin, $foo);
is $foo, $str, 'unparse';
note $foo;

# check for null node. makes sure randoms are
# initialized since :mac=random here.
unlike $foo, qr/-010000000000/, 'not null node';

done_testing;
