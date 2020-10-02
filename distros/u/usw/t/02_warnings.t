use Test::More 0.98 tests => 3;
use lib 'lib';

my @array = qw(0 1 2 3 4 5 6 7 8 9);

$SIG{__WARN__} = sub {
    like $_[0], qr/^\QArgument "2:" isn't numeric in addition (+)/,
        , 'warnings pragma DOES work now';
};

no warnings;    # Of course it defaults no, but declare it explicitly

eval { my $a = "2:" + 3; };    # isn't numeric

is $@, '', 'warnings pragma does NOT work yet';

use usw;                       # turn it on

eval { my $a = "2:" + 3; };    # isn't numeric

no warnings;                   # turn it off again

eval { my $a = "2:" + 3; };    # isn't numeric

is $@, '', 'warnings pragma does NOT work again';

done_testing;
