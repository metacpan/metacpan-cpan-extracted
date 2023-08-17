use strict;
use warnings;
use Test::More;
use Test::Requires qw( Smart::Args::TypeTiny );

use lib qw( ./t/externals/Smart-Args-TypeTiny/lib );

use Type::Alias -alias => [qw( Message )];
use Types::Standard qw( Str );

type Message => Str & sub { length($_) > 1 };

sub hello {
    args my $message => Message;
    return "HELLO " . $message;
}

is hello(message => 'World'), 'HELLO World';

eval { hello(message => '') };
ok $@, 'invalid message';

done_testing;
