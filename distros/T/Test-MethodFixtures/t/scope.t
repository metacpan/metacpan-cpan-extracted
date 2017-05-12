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

subtest in_scope => sub {

        ok my $mocker
            = Test::MethodFixtures->new(
            { storage => '+TestMethodFixtures::Dummy' } ),
            "got mocker";

        ok $mocker->mock('Mocked::Simple::foo'), "mocked sub";

        ok $mocker->mode('record'), "set mode to record";

        ok $mocker->mock('Mocked::Simple::foo'), "mocked simple sub";

        is Mocked::Simple::foo(), 5, "call mocked function";

        is $Mocked::Simple::expensive_call, 1, "called once";

        ok $mocker->mode('playback'), "set mode to playback";

        is Mocked::Simple::foo(), 5, "call mocked function";

        is $Mocked::Simple::expensive_call, 1, "still only called once";

};

subtest out_of_scope => sub {

        is Mocked::Simple::foo(), 5, "call mocked function";

        is $Mocked::Simple::expensive_call, 2, "no longer mocked";

        is Mocked::Simple::foo(), 5, "call mocked function";

        is $Mocked::Simple::expensive_call, 3, "no longer mocked";

};

done_testing();

