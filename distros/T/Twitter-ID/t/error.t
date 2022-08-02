#!perl

use v5.26;
use warnings;
use lib 'lib';

use Test::More;
use Test::Exception;
use Test::Warnings;

plan tests => 7 + 1;


use Twitter::ID;


throws_ok {
	Twitter::ID->new({ timestamp => 1658752613000, sequence => 4096 });
} qr/\btoo large\b/, 'sequence too large';

throws_ok {
	Twitter::ID->new({ timestamp => 1658752613000, worker => 1024 });
} qr/\btoo large\b/, 'worker too large';

throws_ok {
	Twitter::ID->new({ timestamp => 1658752613000, sequence => -1 });
} qr/\bmust be positive\b/, 'negative sequence';

throws_ok {
	Twitter::ID->new({ timestamp => 1658752613000, worker => -1 });
} qr/\bmust be positive\b/, 'negative worker';

throws_ok {
	Twitter::ID->new({ timestamp => 1164086120000, worker => 23 });
} qr/\btimestamp.*\bunsupported\b/, 'timestamp before Twitter epoch';

throws_ok {
	Twitter::ID->new({ timestamp => -1, worker => 23 });
} qr/\btimestamp.*\bunsupported\b/, 'negative timestamp';

throws_ok {
	Twitter::ID->new()->epoch(1380269002.737);
} qr/\bread-only\b/, 'epoch read-only';


done_testing;
