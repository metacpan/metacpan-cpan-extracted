use strict; use warnings;

use Test::More;
use Test::Deep;
use Test::Shadow;

{
    package Foo;
    sub outer {
        my $class = shift;
        for (1..3) {
            my $inner = $class->inner($_);
            return "eeek" unless $inner eq 'inner';
        }
        return "outer";
    }
    sub inner {
        return "inner";
    }
    sub hashy {
        my ($class, %args) = @_;
        return 'hashy';
    }
    sub transform {
        my ($class, $arg) = @_;
        return lc $arg;
    }
}

package main;
subtest "input, Test::Deep, and count" => sub {
    with_shadow Foo => inner => {
        in => [ any(1,2,3) ],
        count => 3,
    }, sub {
        Foo->outer;
    };
};

subtest "change output" => sub {
    with_shadow Foo => inner => {
        out => 'haha',
        count => 1,
    }, sub {
        is (Foo->outer, 'eeek');
    };
};

subtest "Multiple" => sub {
    with_shadow 
        Foo => inner => { out => 'one' },
        Foo => hashy => { out => 'two' },
    sub {
        is (Foo->inner, 'one');
        is (Foo->hashy, 'two');
    };
};

subtest "Hash ref" => sub {
    with_shadow 
        Foo => hashy => { in => { foo => 1, bar => 2 } },
    sub {
        Foo->hashy( foo => 1, bar => 2 );
    };
};

subtest "minmax" => sub {
    with_shadow 
        Foo => hashy => { count => { min => 1, max => 3 } },
    sub {
        Foo->hashy();
        Foo->hashy();
    };
};

subtest "iterate" => sub {
    with_shadow 
        Foo => hashy => { out => Test::Shadow::iterate(1,2,3) },
    sub {
        is(Foo->hashy(), 1, 'iterate 1');
        is(Foo->hashy(), 2, 'iterate 2');
        is(Foo->hashy(), 3, 'iterate 3');
        is(Foo->hashy(), 1, 'iterate back to 1');
    };
};

subtest "out method" => sub {
    with_shadow 
        Foo => transform => { 
            out => sub { my ($orig, $self, $arg) = @_; $self->$orig($arg) x 2 },
        },
    sub {
        is(Foo->transform('heLLo'), 'hellohello', 'delegate and transform');
    }
};

subtest "iterate methods" => sub {
    with_shadow 
        Foo => transform => { 
            out => Test::Shadow::iterate(
                sub { my ($orig, $self, $arg) = @_; uc $arg },
                sub { my ($orig, $self, $arg) = @_; $self->$orig($arg) },
                'override',
                sub { my ($orig, $self, $arg) = @_; $self->$orig($arg) x 2 },
            ) 
        },
    sub {
        is(Foo->transform('heLLo'), 'HELLO', 'override uc');
        is(Foo->transform('heLLo'), 'hello', 'delegate $orig');
        is(Foo->transform('heLLo'), 'override', 'override completely');
        is(Foo->transform('heLLo'), 'hellohello', 'delegate and transform');
    };
};

done_testing;
