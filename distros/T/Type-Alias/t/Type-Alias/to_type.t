use strict;
use warnings;
use Test::More;

use Type::Alias ();
use Types::Standard -types;
use Types::Equal -types;

package MyType {
    sub new { bless {}, shift }
    sub check { 1 }
    sub get_message { 'ok' }
}

subtest 'If type constraint object is passed, return it.' => sub {
    subtest 'If Type::Tiny object is passed, return it.' => sub {
        is Type::Alias::to_type(Int), Int;
        is Type::Alias::to_type(Str), Str;
        is Type::Alias::to_type(ArrayRef[Int]), ArrayRef[Int];
    };

    subtest 'If MyType object is passed, return it.' => sub {
        my $type = MyType->new;
        is Type::Alias::to_type($type), $type;
    };

    subtest 'If object which not define check and get_message methods, throw error.' => sub {
        my $type = bless {}, 'Some';
        eval { Type::Alias::to_type($type) };
        ok $@;
    };
};

subtest 'If arrayref is passed, return Tuple type.' => sub {
    is Type::Alias::to_type([]), Tuple[];
    is Type::Alias::to_type([Int]), Tuple[Int];
    is Type::Alias::to_type([Int, Str]), Tuple[Int, Str];
    is Type::Alias::to_type([Str, Int]), Tuple[Str, Int];
    is Type::Alias::to_type([Str, Int, Str]), Tuple[Str, Int, Str];
    is Type::Alias::to_type([Str, { a => Int }]), Tuple[Str, Dict[a => Int]];
};

subtest 'If hashref is passed, return Dict type.' => sub {
    is Type::Alias::to_type({some => [Int, Str]}), Dict[some => Tuple[Int, Str]];

    note 'Dict keys is sorted by alphabetical order.';
    is Type::Alias::to_type({a => Int, b => Int, c => Int}), Dict[a => Int, b => Int, c => Int];
    is Type::Alias::to_type({b => Int, a => Int, c => Int}), Dict[a => Int, b => Int, c => Int];
};

subtest 'If coderef is passed, return wrapped coderef which returns type. that is, return type function' => sub {
    my $coderef = sub {
        my ($R) = @_;
        $R ? ArrayRef[$R] : ArrayRef;
    };

    my $type = Type::Alias::to_type($coderef);
    is ref $type, 'CODE', 'return type function';

    subtest 'If type function is passed arguments, generate type using the arguments.' => sub {
        is $type->([Int]), ArrayRef[Int];
        is $type->([Str]), ArrayRef[Str];
        is $type->([{a => Int}]), ArrayRef[ Dict[a => Int] ], 'The arguments of type function become type through Type::Alias::to_type.';

        eval { $type->(Int) };
        ok $@, 'Type function requires arguments to be arrayref.';

        is $type->(), ArrayRef, 'If no arguments are passed, return ArrayRef type.';
    };
};

subtest 'If scalarref is passed, throw error.' => sub {
    eval { Type::Alias::to_type(\1) };
    ok $@;
};

subtest 'If regexref is passed, throw error.' => sub {
    eval { Type::Alias::to_type(qr/foo/) };
    ok $@;
};

if (Type::Alias::AVAILABLE_BUILTIN) {
    subtest 'If undef is passed, return Undef type.' => sub {
        is Type::Alias::to_type(undef), Undef;
    };

    subtest 'If boolean is passed, return Boolean type.' => sub {
        is Type::Alias::to_type(!!1), Type::Alias::True;
        is Type::Alias::to_type(!!0), Type::Alias::False;
    };

    subtest 'If number is passed, return NumEq type.' => sub {
        is Type::Alias::to_type(123), NumEq[123];
        is Type::Alias::to_type(0), NumEq[0];
    };

    subtest 'If string is passed, return Eq type.' => sub {
        is Type::Alias::to_type('hello'), Eq['hello'];
        is Type::Alias::to_type('123'), Eq['123'];
        is Type::Alias::to_type(''), Eq[''];
    };
}
else {
    subtest 'If undef is passed, return Undef type.' => sub {
        is Type::Alias::to_type(undef), Undef;
    };

    subtest 'If boolean is passed, return Eq type.' => sub {
        is Type::Alias::to_type(!!1), Eq[!!1];
        is Type::Alias::to_type(!!0), Eq[!!0];
    };

    subtest 'If number is passed, return Eq type.' => sub {
        is Type::Alias::to_type(123), Eq[123];
        is Type::Alias::to_type(0), Eq[0];
    };

    subtest 'If string is passed, return Eq type.' => sub {
        is Type::Alias::to_type('hello'), Eq['hello'];
        is Type::Alias::to_type('123'), Eq['123'];
        is Type::Alias::to_type(''), Eq[''];
    };
}

done_testing;
