use strict;
use warnings FATAL => 'all';
use utf8;
use Test::Kantan;

subtest 'Array', sub {
    subtest 'push', sub {
        subtest 'should push an element', sub {
            my @a = qw(a b c);
            push @a, 'd';
            ok { join( ' ', @a ) eq 'a b c d' };

            diag "HOGE";
        };
    };
};

subtest 'Hash', sub {
    subtest 'fetch', sub {
        subtest 'take the value', sub {
            expect(+{f => 1}->{f})->to_be(1);
            expect(+{f => 1}->{f})->to_equal(1);
        };
    };
};

subtest 'Foo', sub {
    subtest 'bar', sub {
        ok { 1 };
    };
};

done_testing;

