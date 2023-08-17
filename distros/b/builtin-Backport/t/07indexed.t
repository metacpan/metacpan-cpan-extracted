#!/usr/bin/perl

use v5.18;
use warnings;

use builtin;
no warnings 'experimental::builtin';

use Test::More;

# indexed
{
    use builtin qw( indexed );

    is_deeply([indexed], [],
        'indexed on empty list');

    is_deeply([indexed "A"], [0, "A"],
        'indexed on singleton list');

    is_deeply([indexed "X" .. "Z"], [0, "X", 1, "Y", 2, "Z"],
        'indexed on 3-item list');

    my @orig = (1..3);
    $_++ for indexed @orig;
    is_deeply(\@orig, [1 .. 3], 'indexed copies values, does not alias');

$^V ge v5.36.0 and eval <<'EOPERL' || die $@;
    {
        no warnings 'experimental::for_list';

        my $ok = 1;
        foreach my ($len, $s) (indexed "", "x", "xx") {
            length($s) == $len or undef $ok;
        }
        ok($ok, 'indexed operates nicely with multivar foreach');
    }
EOPERL

    {
        my %hash = indexed "a" .. "e";
        is_deeply(\%hash, { 0 => "a", 1 => "b", 2 => "c", 3 => "d", 4 => "e" },
            'indexed can be used to create hashes');
    }

    {
        no warnings ( $^V ge v5.36.0 ) ? 'scalar' : 'void';

        my $count = indexed 'i', 'ii', 'iii', 'iv';
        is($count, 8, 'indexed in scalar context yields size of list it would return');
    }
}

done_testing;
