use strict;
use warnings;
use Test::More;
use Test::Requires qw( Data::Validator );

use lib qw( ./t/externals/Data-Validator/lib );

use Type::Alias -alias => [qw( Message )];
use Types::Standard qw( Str );

type Message => Str & sub { length($_) > 1 };

sub hello {
    my $v = Data::Validator->new( message => Message );
    my $args = $v->validate(@_);

    return "HELLO " . $args->{message};
}

is hello(message => 'World'), 'HELLO World';

eval { hello(message => '') };
ok $@, 'invalid message';

done_testing;
