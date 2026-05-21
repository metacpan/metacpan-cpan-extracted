use warnings;
use MyTest;
use UUID 'uuid';
plan tests => 52;


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

done_testing;
