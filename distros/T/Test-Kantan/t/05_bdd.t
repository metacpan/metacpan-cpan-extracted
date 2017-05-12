use strict;
use warnings;
use Test::Kantan;

describe 'String', sub {
    describe 'index', sub {
        it 'should return -1 when the value is not matched', sub {
            expect(index("abc", 'x'))->to_be(-1);
            expect(index("abc", 'a'))->to_be(0);
        };
    };
};

done_testing;
