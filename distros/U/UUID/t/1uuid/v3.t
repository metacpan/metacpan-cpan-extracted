use strict;
use warnings;
use MyTest;

use vars '@OPTS';

BEGIN {
    @OPTS = qw(uuid3 parse unparse type variant);
}

use UUID @OPTS;

my $bin;
my $str = uuid3(dns => 'www.example.com');
note '';
note $str;

ok defined($str),      'defined';
ok length($str) == 36, 'length';
ok !parse($str, $bin), 'parsable';

# must be v3
my $type = type($bin);
is $type, 3, 'correct type';

# all are variant 1
is variant($bin), 1, 'correct variant';

my $foo;
unparse($bin, $foo);
is $foo, $str, 'unparse';
note $foo;

# --- degenerate case
$str = uuid3( '' => 'www.example.com' );
ok defined($str),      'degen defined';
ok length($str) == 36, 'degen length';
ok !parse($str, $bin), 'degen parsable';
is type($bin), 3,      'degen type';
is variant($bin), 1,   'degen variant';
unparse($bin, $foo);
is $foo, $str, 'degen unparse';
note $foo;

done_testing;
