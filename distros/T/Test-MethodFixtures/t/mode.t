use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::MethodFixtures;

my %mocker_args = ( storage => '+TestMethodFixtures::Dummy' );

subtest default => sub {

        ok my $mocker = Test::MethodFixtures->new( \%mocker_args ),
            "got mocker";
        is $mocker->mode, 'playback', "default mode (playback)";
};

subtest args => sub {
        ok my $mocker
            = Test::MethodFixtures->new( { %mocker_args, mode => 'record' } ),
            "got mocker";
        is $mocker->mode, 'record', "set mode from args";
};

subtest import => sub {

        Test::MethodFixtures->import( '-mode' => 'auto' );
        ok my $mocker = Test::MethodFixtures->new( \%mocker_args ),
            "got mocker";
        is $mocker->mode, 'auto', "set mode from import";

        ok $mocker
            = Test::MethodFixtures->new( { %mocker_args, mode => 'record' } ),
            "got mocker";
        is $mocker->mode, 'record', "set mode from args";
};

done_testing();

