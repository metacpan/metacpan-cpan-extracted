use Test::More;
use VAPID qw/all/;

ok(my ($pub, $priv) = generate_vapid_keys());

ok(validate_subject('mailto:thisusedtobeanemail@gmail.com'));
ok(validate_public_key($pub));
ok(validate_private_key($priv));
ok(validate_expiration(time + 60));

ok(my $header = generate_vapid_header(
	'https://fcm.googleapis.com',
	'mailto:thisusedtobeanemail@gmail.com',
	$pub,
	$priv,
	time + 60
));
diag explain $header;

done_testing();
