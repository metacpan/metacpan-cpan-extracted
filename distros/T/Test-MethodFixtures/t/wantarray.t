use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::MethodFixtures;

BEGIN {

    package Mocked::Wantarray;

    our %expensive_call = (
        list_context   => 0,
        scalar_context => 0,
        void_context   => 0,
    );

    sub foo {

        $expensive_call{    #
            wantarray           ? 'list_context'
            : defined wantarray ? 'scalar_context'
            :                     'void_context'
        }++;

        if (wantarray) {
            return (qw/ foo bar /);
        } elsif ( defined wantarray ) {
            return 'foo';
        } else {
            return;
        }
    }
}

ok my $mocker
    = Test::MethodFixtures->new( { storage => '+TestMethodFixtures::Dummy' } ),
    "got mocker";

ok $mocker->mock('Mocked::Wantarray::foo'), "mocked sub";

subtest list_context => sub {

        ok $mocker->mode('record'), "set mode to record";

        ok my @arr = Mocked::Wantarray::foo(), "call mocked function";

        is_deeply \@arr, [qw/ foo bar /], "call in list context";

        is_deeply \%Mocked::Wantarray::expensive_call,
            { list_context => 1, scalar_context => 0, void_context => 0 },
            "list_context called once";

        ok $mocker->mode('playback'), "set mode to playback";

        ok @arr = Mocked::Wantarray::foo(), "call in list context";

        is_deeply \@arr, [qw/ foo bar /], "call in list context";

        is_deeply \%Mocked::Wantarray::expensive_call,
            { list_context => 1, scalar_context => 0, void_context => 0 },
            "list_context called once";

};

subtest scalar_context => sub {

        ok $mocker->mode('record'), "set mode to record";

        ok my $scalar = Mocked::Wantarray::foo(), "call mocked function";

        is_deeply $scalar, 'foo', "call in scalar context";

        is_deeply \%Mocked::Wantarray::expensive_call,
            { list_context => 1, scalar_context => 1, void_context => 0 },
            "scalar_context called once";

        ok $mocker->mode('playback'), "set mode to playback";

        ok $scalar = Mocked::Wantarray::foo(), "call in scalar context";

        is_deeply $scalar, 'foo', "call in scalar context";

        is_deeply \%Mocked::Wantarray::expensive_call,
            { list_context => 1, scalar_context => 1, void_context => 0 },
            "scalar_context called once";

};

subtest void_context => sub {

        ok $mocker->mode('record'), "set mode to record";

        Mocked::Wantarray::foo();

        is_deeply \%Mocked::Wantarray::expensive_call,
            { list_context => 1, scalar_context => 1, void_context => 1 },
            "void_context called once";

        ok $mocker->mode('playback'), "set mode to playback";

        Mocked::Wantarray::foo();

        is_deeply \%Mocked::Wantarray::expensive_call,
            { list_context => 1, scalar_context => 1, void_context => 1 },
            "void_context called once";

};

done_testing();

