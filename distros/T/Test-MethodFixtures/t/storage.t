use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::MethodFixtures;
use TestMethodFixtures::Dummy;

$Test::MethodFixtures::DEFAULT_STORAGE = '+TestMethodFixtures::Dummy';

my $storage_obj = TestMethodFixtures::Dummy->new();

my %mocker_args = ( mode => 'playback' );

subtest default => sub {

    ok my $mocker = Test::MethodFixtures->new( \%mocker_args ), "got mocker";
    isa_ok $mocker->storage, 'TestMethodFixtures::Dummy',
        "got default storage class";
};

subtest args => sub {

    ok my $mocker
        = Test::MethodFixtures->new(
        { %mocker_args, storage => '+TestMethodFixtures::Alt' } ),
        "got mocker with storage arg";
    isa_ok $mocker->storage, 'TestMethodFixtures::Alt', "set storage class";

    ok $mocker = Test::MethodFixtures->new(
        {   %mocker_args,
            storage => { '+TestMethodFixtures::Alt' => { foo => 'bar' } },
        }
        ),
        "got mocker with storage arg";
    isa_ok $mocker->storage, 'TestMethodFixtures::Alt', "set storage class";

};

subtest import => sub {

    Test::MethodFixtures->import( '-storage' => '+TestMethodFixtures::Alt' );

    ok my $mocker = Test::MethodFixtures->new( \%mocker_args ),
        "got mocker with storage arg";
    isa_ok $mocker->storage, 'TestMethodFixtures::Alt',
        "get new default storage class";

    ok $mocker
        = Test::MethodFixtures->new(
        { %mocker_args, storage => '+TestMethodFixtures::Dummy' } ),
        "got mocker with storage arg";
    isa_ok $mocker->storage, 'TestMethodFixtures::Dummy',
        "args override import";

};

subtest remaining_args => sub {
    ok my $mocker
        = Test::MethodFixtures->new(
        { %mocker_args, storage => '+TestMethodFixtures::Dummy', foo => 'bar' }
        ),
        "got mocker with storage arg";
    isa_ok $mocker->storage, 'TestMethodFixtures::Dummy',
        "args override import";
    ok $mocker->storage->foo, "args passed through";
    is $mocker->storage->foo, "bar", "args passed through";
};

done_testing();

