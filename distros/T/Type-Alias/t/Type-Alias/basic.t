use strict;
use warnings;
use Test::More;

use Type::Alias -alias => [qw( X Y )], -fun => [qw( List )];
use Types::Standard -types;

subtest 'type alias' => sub {

    type X => Str;
    type Y => Int;

    is X, Str;
    is Y, Int;

    is X | Y, Str | Int;
    is X & Y, Str & Int;
};

subtest 'type function' => sub {

    type List => sub {
        my ($R) = @_;
        $R ? ArrayRef[$R] : ArrayRef;
    };

    is List[Str], ArrayRef[Str];
    is List[], ArrayRef;
    is List, ArrayRef;
};

subtest 'type alias and type function' => sub {
    is X | List, Str | ArrayRef;
    is X & List, Str & ArrayRef;
};

done_testing;
