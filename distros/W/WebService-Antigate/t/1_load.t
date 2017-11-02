#!/usr/bin/env perl

use strict;
use Test::More;
BEGIN { use_ok('WebService::Antigate') };
BEGIN { use_ok('WebService::Antigate::V1') };
BEGIN { use_ok('WebService::Antigate::V2') };

my $recognizer = eval { WebService::Antigate->new };
is($recognizer, undef, 'no key specified in the constructor');

$recognizer = eval { WebService::Antigate->new(key => '68b329da9893e34099c7d8ad5cb9c940') };
ok(defined($recognizer), 'constructor') or diag $@;
isa_ok($recognizer, 'WebService::Antigate');

$recognizer = WebService::Antigate->new(key => '68b329da9893e34099c7d8ad5cb9c940', api_version => 1);
isa_ok($recognizer, 'WebService::Antigate::V1');

$recognizer = WebService::Antigate->new(key => '68b329da9893e34099c7d8ad5cb9c940', api_version => 2);
isa_ok($recognizer, 'WebService::Antigate::V2');

$recognizer = WebService::Antigate::V1->new(key => '68b329da9893e34099c7d8ad5cb9c940');
isa_ok($recognizer, 'WebService::Antigate::V1');
isa_ok($recognizer, 'WebService::Antigate');

$recognizer = WebService::Antigate::V2->new(key => '68b329da9893e34099c7d8ad5cb9c940');
isa_ok($recognizer, 'WebService::Antigate::V2');
isa_ok($recognizer, 'WebService::Antigate');

done_testing();
