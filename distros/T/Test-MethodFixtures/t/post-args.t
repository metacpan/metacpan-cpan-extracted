use Test::More;
use Test::Deep;

use strict;
use warnings;

use lib 't/lib';

use Test::MethodFixtures;

BEGIN {

    package Foo;

    sub bar {
        my $class = $_[0];
        return $_[1];
    }

    sub baz {
        my $class = shift;
        return shift;
    }
}

my $mocker
    = Test::MethodFixtures->new(
        { storage => '+TestMethodFixtures::Catcher' } );

$mocker->mock('Foo::bar');
$mocker->mock('Foo::baz');

note 'testing with no altering of @_';

$mocker->mode('record');
Foo->bar(2);
test_record();

$mocker->mode('playback');
Foo->bar(2);
test_playback();

note 'testing with no altering of @_';

$mocker->mode('record');
Foo->baz(2);
test_record();

$mocker->mode('playback');
Foo->baz(2);
test_playback();

done_testing;

sub test_record {
    my $stored    = $mocker->storage->stored;
    my $retrieved = $mocker->storage->retrieved;

    subtest stored => sub {
        ok $stored->{no_output}, "no_output ok";
        is_deeply $stored->{input}, [ 'Foo', 2 ], "input ok";
        is_deeply $stored->{key}, [ { 'wantarray' => undef }, 'Foo', 2 ],
            "key ok";
    };

    subtest retrieved => sub {
        ok !$retrieved, "nothing retrieved yet";
    };

    $mocker->storage->reset();
}

sub test_playback {
    my $stored    = $mocker->storage->stored;
    my $retrieved = $mocker->storage->retrieved;

    subtest stored => sub {
        ok !$stored, "nothing stored";
    };

    subtest retrieved => sub {
        is_deeply $retrieved->{input}, [ 'Foo', 2 ], "input ok";
        is_deeply $retrieved->{key}, [ { 'wantarray' => undef }, 'Foo', 2 ],
            "key ok";
    };
    $mocker->storage->reset();

}

