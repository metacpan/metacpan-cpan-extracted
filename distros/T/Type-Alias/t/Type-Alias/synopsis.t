use strict;
use warnings;
use Test::More;

use Types::Standard -types;
use Type::Alias
    -alias => [qw(ID User Guest LoginUser UserList)],
    -fun => [qw(List)];

type ID => Str;

type LoginUser => {
    _type => 'LoginUser',
    id   => ID,
    name => Str,
    age  => Int,
};

type Guest => {
    _type => 'Guest',
    name => Str,
};

type User => LoginUser | Guest;

type List => sub {
    my ($R) = @_;
    $R ? ArrayRef[$R] : ArrayRef;
};

type UserList => List[User];

ok UserList->check([
    { _type => 'LoginUser', id => '1', name => 'foo', age => 20 },
    { _type => 'Guest', name => 'bar' },
]);

is UserList->display_name, <<'EXPECTED' =~ s/\s//gr;;
    ArrayRef[
        Dict[
            _type => Eq['LoginUser'],
            age => Int,
            id => Str,
            name => Str
        ] |
        Dict[
            _type => Eq['Guest'],
            name => Str
        ]
    ]
EXPECTED

done_testing;
