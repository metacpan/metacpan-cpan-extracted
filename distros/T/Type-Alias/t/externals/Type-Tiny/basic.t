use strict;
use warnings;
use Test::More;
use Test::Requires qw( Types::Standard );

use lib qw( ./t/externals/Type-Tiny/lib );

use Sample qw( ID User List );
use Types::Standard -types;

subtest 'imported types' => sub {
    is ID, Str;
    is User, Dict[id => ID, name => Str, age => Int];
    is List[User], ArrayRef[User];
};

subtest 'union operation' => sub {
    is ID | Str, Str | Str;
    is ID | ID, Str | Str;
    is ID | List[Str], Str | ArrayRef[Str];
    is List[Str] | List[Int], ArrayRef[Str] | ArrayRef[Int];

    my $expected = Dict[id => ID, name => Str, age => Int] | ArrayRef[Dict[id => ID, name => Str, age => Int]];
    is User | List[User], $expected;
};

subtest 'intersection operation' => sub {
    is ID & Str, Str & Str;
    is ID & ID, Str & Str;
    is ID & List[Str], Str & ArrayRef[Str];
    is List[Str] & List[Int], ArrayRef[Str] & ArrayRef[Int];

    my $expected = Dict[id => ID, name => Str, age => Int] & ArrayRef[Dict[id => ID, name => Str, age => Int]];
    is User & List[User], $expected;
};

done_testing;
