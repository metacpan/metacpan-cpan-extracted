use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::MethodFixtures;

BEGIN {

    package Mocked::Simple;

    our $expensive_call = 0;

    sub foo {
        $expensive_call++;
        my $arg = $_[0] || 0;
        return $arg + 5;
    }
}

ok my $mocker
    = Test::MethodFixtures->new( { storage => '+TestMethodFixtures::Dummy' } ),
    "got mocker";

ok $mocker->mock('Mocked::Simple::foo'), "mocked simple sub";

call( passthrough => 1 );
call( record => 2 );
call( playback => 2 );
call( passthrough => 3 );

sub call {
    my ( $mode, $times ) = @_;

    ok $mocker->mode($mode), "set mode to $mode";

    is Mocked::Simple::foo(1), 6, "call mocked function";

    is $Mocked::Simple::expensive_call, $times, "called $times times";
}

done_testing();

