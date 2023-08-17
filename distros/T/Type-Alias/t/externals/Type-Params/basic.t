use strict;
use warnings;
use Test::More;
use Test::Requires {
    'Type::Params' => '2.000000',
};

use Type::Alias -alias => [qw( Message )];
use Types::Standard qw( Str );
use Type::Params -sigs;

type Message => Str & sub { length($_) > 1 };

signature_for hello => (
    positional => [ Message ],
);

sub hello {
    my ($message) = @_;
    return "HELLO " . $message;
}

is hello('World'), 'HELLO World';

eval { hello('') };
ok $@, 'invalid message';

done_testing;
