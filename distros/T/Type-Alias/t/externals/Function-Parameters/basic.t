use strict;
use warnings;
use Test::More;
use Test::Requires 'Function::Parameters';

use lib qw( ./t/externals/Function-Parameters/lib );

use Types::Standard -types;
use Function::Parameters;

subtest 'import type alias' => sub {
    use Sample qw(User);

    fun hello (User $user) {
        return "Hello, $user->{name}!";
    }

    is hello({ name => 'foo' }), 'Hello, foo!';
};

subtest 'define type alias on the fly' => sub {
    TODO: {
        local $TODO = 'not implemented yet';
        fail;
    }

    #    use Type::Alias -alias => [qw(Gorilla)];
    #
    #    type Gorilla => Dict[ name => Str ];
    #
    #    fun ooh(Gorilla $user) {
    #        return "ooh ooh, $user->{name}!";
    #    }
    #
    #    is ooh({ name => 'gorilla' }), 'ooh ooh, gorilla!';
};

done_testing;
