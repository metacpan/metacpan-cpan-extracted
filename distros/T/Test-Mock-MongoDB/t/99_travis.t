use strict;
use warnings;

use MongoDB;
use Test::More;

use Test::Mock::MongoDB;

my $is_travis = $ENV{'TRAVIS'} || '';
if ($is_travis ne 'true') {
    plan skip_all => 'test only on travis-ci environment';
}

# http://docs.travis-ci.com/user/database-setup/#sts=MongoDB
# will try to connect next 15 seconds until successfull connect
my $mongo   = MongoDB::MongoClient->new(auto_connect => 0);
my $timeout = 15;
my $err;

while (--$timeout) {
    eval {
        $mongo->connect;
    };
    $err = $@;

    last unless $err;
} continue {
    sleep 1;
}

if ($err) {
    plan skip_all => 'mongo is not accessible';
}

my $mock = Test::Mock::MongoDB->new(skip_init => 'all');
my $db = $mongo->get_database('travis');
$db->drop;
my $collection = $db->get_collection('users');
my $document;

my $petr = {
    name => 'petr',
    age  => 27
};
my $ivan = {
    name => 'ivan',
    age  => 27
};
my $mocked_ivan = {
    name => 'ivan',
    age  => 42
};
$collection->batch_insert([$petr, $ivan]);

subtest 'before mock' => sub {
    $document = $collection->find_one({name => 'petr'}, {_id => 0});
    is_deeply($document, $petr, 'find_one(petr) default behavior');

    $document = $collection->find_one({name => 'ivan'}, {_id => 0});
    is_deeply($document, $ivan, 'find_one(ivan) default behavior');

    done_testing;
};

$mock->get_collection->method(find_one => { name => 'ivan'})->callback(
    sub {
        return $mocked_ivan;
    }
);

subtest 'after mock' => sub {
    $document = $collection->find_one({name => 'petr'}, {_id => 0});
    is_deeply($document, $petr, 'find_one(petr) default behavior');

    $document = $collection->find_one({name => 'ivan'}, {_id => 0});
    is_deeply($document, $mocked_ivan, 'find_one(ivan) mocked behavior');

    done_testing;
};
$db->drop;

done_testing;
