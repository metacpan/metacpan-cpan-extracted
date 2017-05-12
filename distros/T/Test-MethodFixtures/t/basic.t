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

    package Mocked::Args;

    our $expensive_call = 0;

    sub foo {
        $expensive_call++;
        return $_[0] * $_[1];
    }

    package Mocked::Object;

    sub new {
        my ( $class, %args ) = @_;
        return bless \%args, $class;
    }

    sub foo {
        my ( $self, @args ) = @_;
        $self->{expensive_call}++;
        return $args[0] * $args[1] * $self->{multiplier};
    }
}

ok my $mocker
    = Test::MethodFixtures->new( { storage => '+TestMethodFixtures::Dummy' } ),
    "got mocker";

subtest Simple => sub {

        ok $mocker->mode('record'), "set mode to record";

        ok $mocker->mock('Mocked::Simple::foo'), "mocked simple sub";

        is Mocked::Simple::foo(), 5, "call mocked function";

        is $Mocked::Simple::expensive_call, 1, "called once";

        ok $mocker->mode('playback'), "set mode to playback";

        is Mocked::Simple::foo(), 5, "call mocked function";

        is $Mocked::Simple::expensive_call, 1, "still only called once";
};

subtest Simple => sub {

        ok $mocker->mode('record'), "set mode to record";

        ok $mocker->mock('Mocked::Simple::foo'), "mocked simple sub";

        is Mocked::Simple::foo(1), 6, "call mocked function";

        is $Mocked::Simple::expensive_call, 2, "called once";

        ok $mocker->mode('playback'), "set mode to playback";

        is Mocked::Simple::foo(1), 6, "call mocked function";

        is $Mocked::Simple::expensive_call, 2, "still only called once";
};

subtest Args => sub {

        ok $mocker->mode('record'), "set mode to record";

        ok $mocker->mock('Mocked::Args::foo'), "mocked sub with args";

        is Mocked::Args::foo( 3, 3 ), 9,  "call mocked function";
        is Mocked::Args::foo( 4, 3 ), 12, "call mocked function";
        is Mocked::Args::foo( 0, 3 ), 0,  "call mocked function";

        is $Mocked::Args::expensive_call, 3, "called 3 times";

        ok $mocker->mode('playback'), "set mode to playback";

        is Mocked::Args::foo( 0, 3 ), 0,  "call mocked function";
        is Mocked::Args::foo( 4, 3 ), 12, "call mocked function";
        is Mocked::Args::foo( 3, 3 ), 9,  "call mocked function";

        is $Mocked::Args::expensive_call, 3, "still only called 3 times";

};

subtest Object => sub {

        ok $mocker->mode('record'), "set mode to record";

        ok $mocker->mock( 'Mocked::Object::foo', sub { $_[0]->{name} } ),
            "mocked object method";

        my $object1 = Mocked::Object->new( name => "bob",  multiplier => 3 );
        my $object2 = Mocked::Object->new( name => "dave", multiplier => 2 );

        is $object1->foo( 3, 3 ),  27, "called mocked method";
        is $object1->foo( 0, 3 ),  0,  "called mocked method";
        is $object1->foo( 3, 10 ), 90, "called mocked method";

        is $object1->{expensive_call}, 3, "called 3 times";

        is $object2->foo( 3, 3 ), 18, "called mocked method";
        is $object2->foo( 0, 3 ), 0,  "called mocked method";

        is $object2->{expensive_call}, 2, "called 2 times";

        ok $mocker->mode('playback'), "set mode to playback";

        is $object1->foo( 3, 3 ),  27, "called mocked method";
        is $object1->foo( 0, 3 ),  0,  "called mocked method";
        is $object1->foo( 3, 10 ), 90, "called mocked method";

        is $object1->{expensive_call}, 3, "still called 3 times";

        is $object2->foo( 3, 3 ), 18, "called mocked method";
        is $object2->foo( 0, 3 ), 0,  "called mocked method";

        is $object2->{expensive_call}, 2, "still called 2 times";
};

done_testing();

