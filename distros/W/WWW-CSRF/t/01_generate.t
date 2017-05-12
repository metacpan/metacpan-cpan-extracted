use Test::More tests => 6;

use WWW::CSRF qw(generate_csrf_token);

my $random = pack('H*', '112233445566778899aabbccddeeff0011223344');

like(generate_csrf_token("id", "secret"),
     qr/^[0-9a-f]{40},[0-9a-f]{40},\d+$/,
     "token has right format");

is(generate_csrf_token("id", "secret", { Random => $random, Time => 1234567890 }),
   "5df5e9f17c929a45af5d33624ec052903599958f,112233445566778899aabbccddeeff0011223344,1234567890",
   "generate simple token");

is(generate_csrf_token("id", "s3cret", { Random => $random, Time => 1234567890 }),
   "0acb0abac254d21ce30c2e805a1bf6762e0b6a17,112233445566778899aabbccddeeff0011223344,1234567890",
   "different secret changes token");

is(generate_csrf_token("id", "s3cret", { Random => $random, Time => 1234567891 }),
   "8e5c2d1cd2dc0368ed2fa1facee31660a5ffa12f,112233445566778899aabbccddeeff0011223344,1234567891",
   "different time changes token");

$random = pack('H*', '112233445566778899aabbccddeeff0011223340');
is(generate_csrf_token("id", "secret", { Random => $random, Time => 1234567890 }),
   "5df5e9f17c929a45af5d33624ec052903599958b,112233445566778899aabbccddeeff0011223340,1234567890",
   "bitflip in mask flips corresponding bit in token");

$random = pack('H*', '112233445566778899aabbccddeeff00112233');
eval {
  my $ignored = generate_csrf_token("id", "secret", { Random => $random, Time => 1234567890 });
};
ok($@, "check that wrong amount of randomness causes die()");
