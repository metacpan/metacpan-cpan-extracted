use strict;
use lib qw(./t/lib ./lib);
use Monkey;
use Test::Expectation;
use Data::Dumper;
use Test::More;
use Test::Exception;

it_is_a 'Monkey';

it_should "eat a banana", sub {
    Monkey->expects('banana');
    Monkey->eat();
};

it_should "look at a lady monkey", sub {
    Monkey->expects('focus')->with('lady monkey');
    Monkey->look();
};

it_should "defend itself", sub {
    Monkey->expects('swing')->to_return('punches');

    is(
        Monkey->fight,
        'punches',
        'monkey fights real good'
    );
};

it_should "scratch itself", sub {
    Monkey->expects('itch')->with('bite')->to_return('swelling');

    Monkey->scratch();
};

it_should "explode when it smokes dynamite", sub {
    Monkey->expects('cigar')->to_raise('kaboom!');

    is(
        Monkey->smoke(),
        'oops!',
        'monkey smoked dynamite'
    );
};

it_should "eat meat and veg", sub {
    Monkey->expects('diet')->to_return('meat', 'veg');

    my @expectedDiet = ('meat', 'veg');
    my @diet = Monkey->diet();

    is_deeply(
        \@diet,
        \@expectedDiet,
        'monkey likes different foods'
    );
};

# some error checking

{ # check we cannot set two expectations
    throws_ok(
        sub {
            Monkey->expects('fur')->expects('baldness');
        },
        qr/Cannot set multiple expectations against a single method/,
        'double-expect check'
    );
}

{ # check we cannot set two negative expectations
    throws_ok(
        sub {
            Monkey->does_not_expect('gravity')->does_not_expect('bananas');
        },
        qr/Cannot set multiple expectations against a single method/,
        'double-negative check'
    );
}

{ #check that we cannot set "with" twice
    throws_ok(
        sub {
            Monkey->expects('play')->with('itself')->with('itself');
        },
        qr/Cannot define "with" more than once against a single expectation/,
        'double-with check'
    );
}

{ # check that we cannot set two return expectations
    throws_ok(
        sub {
            Monkey->expects('banana')->to_return('yum')->to_return('yuck!')
        },
        qr/Cannot set more that one return expectation/,
        'double-return check'
    );
}

{ # check that we cannot expect more than one exception
    throws_ok(
        sub {
            Monkey->expects('gravity')->to_raise('the sun')->to_raise('objects');
        },
        qr/Cannot expect more than one exception/,
        'double-exception check'
    );
}
