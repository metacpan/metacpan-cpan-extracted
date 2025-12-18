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

# Test validate_subscription
my $valid_subscription = {
	endpoint => 'https://fcm.googleapis.com/fcm/send/test-endpoint',
	keys => {
		p256dh => $pub,
		auth => 'dGVzdGF1dGhrZXkxMjM0NQ'
	}
};

ok(validate_subscription($valid_subscription), 'validate_subscription with valid subscription');

# Test invalid subscriptions
eval { validate_subscription() };
ok($@ =~ /No subscription/, 'validate_subscription dies without subscription');

eval { validate_subscription('not a hash') };
ok($@ =~ /must be a hash/, 'validate_subscription dies with non-hash');

eval { validate_subscription({}) };
ok($@ =~ /must have an endpoint/, 'validate_subscription dies without endpoint');

eval { validate_subscription({ endpoint => 'https://example.com' }) };
ok($@ =~ /must have keys/, 'validate_subscription dies without keys');

eval { validate_subscription({ endpoint => 'https://example.com', keys => {} }) };
ok($@ =~ /must have a p256dh/, 'validate_subscription dies without p256dh');

eval { validate_subscription({ endpoint => 'https://example.com', keys => { p256dh => 'test' } }) };
ok($@ =~ /must have an auth/, 'validate_subscription dies without auth');

# Test encrypt_payload
my ($enc_pub, $enc_priv) = generate_vapid_keys();
my $test_subscription = {
	endpoint => 'https://fcm.googleapis.com/fcm/send/test',
	keys => {
		p256dh => $enc_pub,
		auth => 'dGVzdGF1dGhrZXkxMjM0NQ'
	}
};

ok(my $encrypted = encrypt_payload('Test message', $test_subscription), 'encrypt_payload works');
ok($encrypted->{ciphertext}, 'encrypt_payload returns ciphertext');
ok($encrypted->{salt}, 'encrypt_payload returns salt');
ok($encrypted->{local_public_key}, 'encrypt_payload returns local_public_key');

# Test encrypt_payload validation
eval { encrypt_payload() };
ok($@ =~ /No payload/, 'encrypt_payload dies without payload');

# Test build_push_request
ok(my $req = build_push_request(
	subscription => $test_subscription,
	payload => 'Hello World',
	vapid_public => $pub,
	vapid_private => $priv,
	subject => 'mailto:test@example.com',
	ttl => 120
), 'build_push_request works');

isa_ok($req, 'HTTP::Request', 'build_push_request returns HTTP::Request');
is($req->method, 'POST', 'request method is POST');
ok($req->header('Authorization'), 'request has Authorization header');
ok($req->header('TTL'), 'request has TTL header');
is($req->header('TTL'), 120, 'TTL header has correct value');
ok($req->header('Content-Encoding'), 'request has Content-Encoding header');
ok($req->header('Encryption'), 'request has Encryption header');

# Test build_push_request without payload
ok(my $req_no_payload = build_push_request(
	subscription => $test_subscription,
	vapid_public => $pub,
	vapid_private => $priv,
	subject => 'mailto:test@example.com'
), 'build_push_request works without payload');

is($req_no_payload->header('Content-Length'), 0, 'Content-Length is 0 without payload');

# Test enc parameter for vapid header
ok(my $enc_header = generate_vapid_header(
	'https://fcm.googleapis.com',
	'mailto:thisusedtobeanemail@gmail.com',
	$pub,
	$priv,
	time + 60,
	1
), 'generate_vapid_header with enc parameter');
ok($enc_header->{Authorization} =~ /^vapit t=/, 'enc mode uses vapit format');

done_testing();
