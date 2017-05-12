use strict;
use warnings;
use utf8;
use Test::Kantan;

subtest 'Array', sub {
    subtest 'push', sub {
        subtest 'should push an element', sub {
            my @a=qw(a b c);
            push @a, 'd';
            ok { join(' ', @a) eq 'a b c d e' };

            diag "HOGE";
        };
    };
};

subtest 'Hash', sub {
    subtest 'fetch', sub {
        my $h = +{ f => 1 };
        subtest 'take the value', sub {
            expect($h->{g})->to_be_true;
        };
        subtest 'take the value', sub {
            ok { $h->{g} };
        };
    };
};

done_testing;
