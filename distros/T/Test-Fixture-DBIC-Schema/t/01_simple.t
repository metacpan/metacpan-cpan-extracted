use strict;
use warnings;
use Test::More;
use t::Tools;
use Test::Fixture::DBIC::Schema;
use File::Temp qw/tempfile/;
use Test::Requires 'DBD::SQLite';

plan tests => 17;

schema->storage->dbh->do(
    q{
        INSERT INTO artist (artistid, name) VALUES (1, 'foo');
    }
);

is schema->resultset('Artist')->count, 1;

my @fixture_sources = (
    't/fixture.yaml',
    [
        {
            data => {
                cdid   => 3,
                artist => 2,
                title  => 'foo',
                year   => 2007,
            },
            schema => 'CD',
            name   => 'cd',
        },
        {
            data => {
                artistid => 2,
                name     => 'beatles',
            },
            schema => 'Artist',
            name   => 'artist',
        },
    ]
);

for my $fixture_src (@fixture_sources) {
    my $fixture = construct_fixture(
        schema  => schema,
        fixture => $fixture_src
    );

    is schema->resultset('Artist')->count, 1;
    is schema->resultset('CD')->count, 1;
    is schema->resultset('ViewAll')->count, 1;
    ok $fixture->{cd}, 'has key';
    ok $fixture->{artist}, 'has key';
    is $fixture->{cd}->id, 3;
    is $fixture->{cd}->title, 'foo';
    is $fixture->{artist}->name, 'beatles';
}

