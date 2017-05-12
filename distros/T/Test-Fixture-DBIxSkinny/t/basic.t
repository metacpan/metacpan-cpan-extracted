use strict;
use warnings;
use Test::More;
use Test::Fixture::DBIxSkinny;
use Test::Requires 'DBD::SQLite';
use lib './t/lib';
use Mock::DB;

my @fixture_sources = (
    't/fixture.yaml',
    [
        {
            data => {
                id   => 1,
                name => 'nekokak',
            },
            table => 'foo',
            name  => 'foo1',
        },
        {
            data => {
                id   => 2,
                name => 'tokuhirom',
            },
            table => 'foo',
            name  => 'foo2',
        },
        {
            data => {
                id   => 1,
                name => 'kan',
            },
            table => 'bar',
            name  => 'bar1',
        },
    ]
);

my $db = Mock::DB->new({dsn => 'dbi:SQLite:'});
$db->do(q{
    CREATE TABLE foo (
        id   INT,
        name TEXT
    )
});
$db->do(q{
    CREATE TABLE bar (
        id   INT,
        name TEXT
    )
});

for my $fixture_src (@fixture_sources) {
    my $fixture = construct_fixture(
        db      => $db,
        fixture => $fixture_src
    );

    is $db->count('foo' => 'id'), 2;
    is $db->count('bar' => 'id'), 1;
    ok $fixture->{foo1}, 'has key';
    ok $fixture->{foo2}, 'has key';
    ok $fixture->{bar1}, 'has key';
    is $fixture->{foo1}->id, 1;
    is $fixture->{foo1}->name, 'nekokak';
    is $fixture->{foo2}->name, 'tokuhirom';
    is $fixture->{bar1}->name, 'kan';
}

done_testing;

