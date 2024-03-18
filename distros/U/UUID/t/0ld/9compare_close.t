use warnings;
use Test::More tests => 52;
use UUID 'uuid';


# core dumps seemed to be triggered mainly when
# two calls to compare() were very close together.

my ($bin1, $bin2);

UUID::generate($bin1);
ok 1, 'gen1';

UUID::generate_random($bin2);
ok 1, 'gen2';

for my $n ( 1 .. 50 ) {
    my @foo = (
        UUID::compare($bin1,$bin2),
        UUID::compare($bin1,$bin2),
    );
    ok 1, "close $n";
}

exit 0;
