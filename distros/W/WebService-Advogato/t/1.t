use Test::More tests => 8;
BEGIN { use_ok('WebService::Advogato') };

my $client = new WebService::Advogato();

is($client->capitalize('aeIoU'), 'AEIOU', 'capitalize');
is(join(' ', $client->guess()), 'You guessed 42', 'guess');
is($client->square(9), 81, 'square');
is($client->strlen('abcdefghijklmnopqrstuvwxyz'), 26, 'strlen');
ok(eq_array([$client->sumprod(9, 6)], [15, 54]), 'sumprod');
is($client->level('raph'), 'Master');
is($client->exists('jaldhar'), 1);
