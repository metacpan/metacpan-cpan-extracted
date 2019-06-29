#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Fatal 'exception';
use Test::Deep;
use Test::Mock::Redis ();

#
# first demonstrate failure
#
my $r1 = Test::Mock::Redis->new(server => '1.1.1.1:1111');

like exception { $r1->select(19) }, qr/\QYou called select(19), but max allowed is 15/;


#
# now change the setting
#
# the equivalent of 'use $class num_databases => 20'
Test::Mock::Redis->import(num_databases => 20);

# need a different server since the first one is already set up in $instances
my $r2 = Test::Mock::Redis->new(server => '2.2.2.2:2222');
$r2->set('key-in-default-db-0', 'foobar');

# now this will pass
is exception { $r2->select(19) }, undef;

# and this won't include key-in-default-db-0
$r2->set('key1', 'foobar');
$r2->set('key2', 'foobar');
cmp_deeply( [ $r2->keys('*') ], bag('key1', 'key2'));


#
# allow alternate syntax, a method that says what it does, if the user wants
# to change it during the run of the test
#
Test::Mock::Redis::change_num_databases(30);
my $r3 = Test::Mock::Redis->new(server => '3.3.3.3:3333');
$r3->set('key-in-default-db-0', 'foobar');

# now this will pass
is exception { $r3->select(29) }, undef;

# and this won't include key-in-default-db-0
$r3->set('key1', 'foobar');
$r3->set('key2', 'foobar');
cmp_deeply( [ $r3->keys('*') ], bag('key1', 'key2'));

done_testing();


