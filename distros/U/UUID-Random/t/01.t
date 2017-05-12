use Test::More tests => 1;

use UUID::Random;

my $uuid = UUID::Random::generate;

like($uuid, qr/^[abcdef1234567890]{8}-[abcdef1234567890]{4}-[abcdef1234567890]{4}-[abcdef1234567890]{4}-[abcdef1234567890]{12}$/);
