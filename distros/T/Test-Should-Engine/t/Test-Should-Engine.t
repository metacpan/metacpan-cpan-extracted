use strict;
use warnings;
use utf8;
use Test::Should::Engine;
use Test::More;

sub describe { goto &Test::More::subtest }
sub context  { goto &Test::More::subtest }
sub it       { goto &Test::More::subtest }

sub test_true {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    ok(Test::Should::Engine->run(@_));
}

sub test_false {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    ok(!Test::Should::Engine->run(@_));
}

describe 'Test::Should::Engine' => sub {
    context 'should_be_ok' => sub {
        it 'returns true on true value' => sub {
            test_true('should_be_ok', 1);
        };
        it 'returns false on false value' => sub {
            test_false('should_be_ok', 0);
        };
    };
    context 'should_be_true' => sub {
        it 'returns true on true value' => sub {
            test_true('should_be_true', 1);
        };
        it 'returns false on false value' => sub {
            test_false('should_be_true', 0);
        };
    };
    context 'should_be_false' => sub {
        it 'returns false on false value' => sub {
            test_false('should_be_false', 1);
        };
        it 'returns true on false value' => sub {
            test_true('should_be_false', 0);
        };
    };
    context 'should_be_undef' => sub {
        it 'returns true on undef value' => sub {
            test_true('should_be_undef', undef);
        };
        it 'returns false on defined value' => sub {
            test_false('should_be_undef', 0);
        };
    };
    context 'should_not_be_ok' => sub {
        it 'returns false on true value' => sub {
            test_false('should_not_be_ok', 1);
        };
        it 'returns true on false value' => sub {
            test_true('should_not_be_ok', 0);
        };
    };
    context 'should_be_empty' => sub {
        it 'returns true on empty arrayref' => sub {
            test_true('should_be_empty', []);
        };
        it 'returns false on non-empty arrayref' => sub {
            test_false('should_be_empty', [1]);
        };
        it 'returns true on empty string' => sub {
            test_true('should_be_empty', '');
        };
        it 'returns false on non-empty string' => sub {
            test_false('should_be_empty', 'hoge');
        };
    };
    context 'should_be_equal' => sub {
        it 'returns true on same values' => sub {
            test_true('should_be_equal', {a => 'b'}, {a => 'b'});
        };
        it 'returns true on same scalars' => sub {
            test_true('should_be_equal', 1, 1);
        };
        it 'returns true on non-same values' => sub {
            test_false('should_be_equal', {a => 'b'}, {a => 'c'});
        };
    };
    context 'should_be_a' => sub {
        it 'returns true on child class' => sub {
            test_true('should_be_a', bless([], 'Foo'), 'Foo');
        };
        it 'returns false on non-child class' => sub {
            test_false('should_be_a', bless([], 'Foo'), 'Bar');
        };
    };
    context 'should_be_an' => sub {
        it 'returns true on child class' => sub {
            test_true('should_be_an', bless([], 'Foo'), 'Foo');
        };
        it 'returns false on non-child class' => sub {
            test_false('should_be_an', bless([], 'Foo'), 'Bar');
        };
    };
    context 'should_be_above' => sub {
        it 'returns true on above value' => sub {
            test_true('should_be_above', 9, 5);
        };
        it 'returns false on same value' => sub {
            test_false('should_be_above', 5, 5);
        };
        it 'returns false on belo value' => sub {
            test_false('should_be_above', 2, 5);
        };
    };
    context 'should_be_below' => sub {
        it 'returns true on below value' => sub {
            test_true('should_be_below', 2, 5);
        };
        it 'returns false on same value' => sub {
            test_false('should_be_below', 5, 5);
        };
        it 'returns false on belo value' => sub {
            test_false('should_be_below', 9, 5);
        };
    };
    context 'should_match' => sub {
        it 'returns true on matched' => sub {
            test_true('should_match', 'hoge', qr/h.ge/);
        };
        it 'returns false on not matched' => sub {
            test_false('should_match', 'hoge', qr/hige/);
        };
    };
    context 'should_have_length' => sub {
        context 'when argument is a string' => sub {
            it 'returns true on matched' => sub {
                test_true('should_have_length', 'hoge', 4);
            };
            it 'returns false on not matched' => sub {
                test_false('should_have_length', 'hoge', 2);
            };
        };

        context 'when argument is an array' => sub {
            it 'returns true on matched' => sub {
                test_true('should_have_length', [1, 2, 3], 3);
            };
            it 'returns false on not matched' => sub {
                test_false('should_have_length', [1, 2, 3], 2);
            };
        };
    };
    context 'should_include' => sub {
        it 'returns true when arrayref includes value' => sub {
            test_true('should_include', [1,2,3], 1);
        };
        it 'returns false when arrayref includes value' => sub {
            test_false('should_include', [1,2,3], 4);
        };
        it 'returns true when string includes substring' => sub {
            test_true('should_include', 'ablabra', 'bra');
        };
        it 'returns false when string does not includes substring' => sub {
            test_false('should_include', 'ablabra', 'obra');
        };
    };
    context 'should_throw' => sub {
        it 'returns true on throws.' => sub {
            test_true('should_throw', sub { die });
        };
        it 'can match to regexp' => sub {
            test_true('should_throw', sub { die "xaicron" }, qr/cron/);
        };
        it 'return fales when regexp does not match' => sub {
            test_false('should_throw', sub { die "xaicron" }, qr/shachi/);
        };
    };
    context 'should_have_keys' => sub {
        it 'returns true on matched *exactly*' => sub {
            test_true('should_have_keys', +{foo => 'bar', baz => 'boz'}, 'foo', 'baz');
        };
        it 'returns false on non matched *exactly*' => sub {
            test_false('should_have_keys', +{foo => 'bar', baz => 'boz'}, 'foo', 'bar');
        };
    };
};

done_testing;

