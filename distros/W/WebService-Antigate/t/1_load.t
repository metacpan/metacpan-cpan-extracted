#!/usr/bin/env perl

use strict;
use Test::More;
BEGIN { use_ok('WebService::Antigate') };

my $recognizer = eval { WebService::Antigate->new };
is($recognizer, undef, 'no key specified in the constructor');

$recognizer = eval { WebService::Antigate->new(key => '68b329da9893e34099c7d8ad5cb9c940') };
ok(defined($recognizer), 'constructor') or diag $@;
isa_ok($recognizer, 'WebService::Antigate');

done_testing();

