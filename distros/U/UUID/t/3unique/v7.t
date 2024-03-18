use strict;
use warnings;
use Test::More;
use MyNote;
BEGIN { use_ok 'UUID' }

my $n = 100;
my %seen = ();

for (1 .. $n) {
    my ($bin, $str);
    UUID::generate_v7($bin);
    UUID::unparse($bin, $str);
    ok !exists($seen{$str}), $str;
    $seen{$str} = 1;
}

is scalar(keys %seen), $n, 'no dupes';

done_testing;
