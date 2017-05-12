use strict;
use warnings;

use Test::More;

use Test::Mock::MongoDB qw( any );
use MongoDB;

# mock objects
my $mock         = Test::Mock::MongoDB->new;
my $m_client     = $mock->get_client;
my $m_database   = $mock->get_database;
my $m_collection = $mock->get_collection;
my $m_cursor     = $mock->get_cursor;

# real objects
my $client = MongoDB::MongoClient->new(
    host => '127.0.0.1',
    port => 27017
);
my $db = $client->get_database('foo');
my $collection = $db->get_collection('bar');
my $cursor = $collection->find({ something => 42 });

subtest 'mongoclient' => sub {
    isa_ok($m_client, 'Test::Mock::MongoDB::MongoClient');
    isa_ok($client, 'MongoDB::MongoClient');

    $m_client->method('database_names')->callback(
        sub {
            return qw(foo bar baz);
        }
    );

    my @dbs = $client->database_names;
    is_deeply(\@dbs, [ qw(foo bar baz) ], 'database_names mock');

    done_testing;
};

subtest 'database' => sub {
    isa_ok($m_database, 'Test::Mock::MongoDB::Database');
    isa_ok($db, 'MongoDB::Database');

    $m_database->method(last_error => { w => 42 })->callback(
        sub {
            return { ok => 1 }
        }
    );

    my $err = $db->last_error({ w => 42 });
    is_deeply($err, { ok => 1 }, 'last_error mock');

    done_testing;
};

subtest 'collection' => sub {
    isa_ok($m_collection, 'Test::Mock::MongoDB::Collection');
    isa_ok($collection, 'MongoDB::Collection');

    $m_collection->method(insert => { name => any })->callback(
        sub { 42 }
    );
    is($collection->insert({ name => 'cono'}), 42, 'insert mock');

    done_testing;
};

subtest 'cursor' => sub {
    isa_ok($m_cursor, 'Test::Mock::MongoDB::Cursor');
    isa_ok($cursor, 'MongoDB::Cursor');

    $m_cursor->method('next')->callback(
        sub { 'test' }
    );
    is($cursor->next, 'test', 'next mock');

    done_testing;
};

done_testing;
