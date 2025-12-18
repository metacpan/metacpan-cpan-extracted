package VAPID;
use 5.006; use strict; use warnings; our $VERSION = '1.05';
use Crypt::JWT qw(encode_jwt); use Crypt::PK::ECC; use URI; use MIME::Base64 qw/encode_base64url decode_base64url/; 
use Crypt::AuthEnc::GCM qw(gcm_encrypt_authenticate); use Crypt::KeyDerivation qw(hkdf); use Crypt::PRNG qw(random_bytes); 
use HTTP::Request; use LWP::UserAgent; use JSON qw(decode_json);
use base 'Import::Export';

our (%EX, $DEFAULT_SECONDS, $MAX_DEFAULT_SECONDS);

BEGIN {
	$DEFAULT_SECONDS = 12 * 60 * 60; # 12 hours
	$MAX_DEFAULT_SECONDS = 24 * 60 * 60; # 24 hours
	%EX = (
		generate_vapid_keys => [qw/all generate/],
		generate_future_expiration_timestamp => [qw/all generate/],
		generate_vapid_header => [qw/all generate/],
		validate_subject => [qw/all validate/],
		validate_public_key => [qw/all validate/],
		validate_private_key => [qw/all validate/],
		validate_expiration_key => [qw/all validate/],
		validate_expiration => [qw/all validate/],
		validate_subscription => [qw/all validate/],
		encrypt_payload => [qw/all encrypt/],
		build_push_request => [qw/all push/],
		send_push_notification => [qw/all push/],
	);
}

sub generate_vapid_keys {
	my $curve = Crypt::PK::ECC->new();
	$curve->generate_key('prime256v1');
	my $priv = $curve->export_key_raw('private');
	my $pub = $curve->export_key_raw('public');
	
	if (length($priv) < 32) {
		my $padding = 32 - length $priv;
		$priv = (0 x $padding) . $priv;
	}
	
	if (length($pub) < 65) {
		my $padding = 65 - length $pub;
		$pub = (0 x $padding) . $pub;
	}

	return (
		encode_base64url($pub),
		encode_base64url($priv)
	);
}

sub generate_vapid_header {
	my ($aud, $subject, $pub, $priv, $expiration, $enc) = @_;

	if (!$aud) {
		die "No audience could be generated for VAPID.";
	}

	if (ref $aud) {
		die "The audience value must be a string containing the origin of a push service";
	}

	my $aud_uri = URI->new($aud);

	if (!$aud_uri->host) {
		die "VAPID audience is not a url.";
	}

	validate_subject($subject);
	validate_public_key($pub);
	$priv = validate_private_key($priv);

	if ($expiration) {
		validate_expiration($expiration);
	} else {
		$expiration = generate_future_expiration_timestamp();
	}

	my $payload = {
		aud => $aud,
    		exp => $expiration,
   		sub => $subject
	};

	my $key = Crypt::PK::ECC->new
		->import_key_raw($priv, 'prime256v1')
		->export_key_pem('private');


	my $jwt_token = encode_jwt(
		payload=>$payload, 
		extra_headers => { typ => 'JWT' }, 
		alg=>'ES256', 
		key => \$key
	);

	return $enc 
		? {
			Authorization => "vapit t=${jwt_token}, k=${pub}"
		}
		: {
			Authorization => 'WebPush ' . $jwt_token,
      			'Crypto-Key' => 'p256ecdsa=' . $pub
		}; 
}

sub generate_future_expiration_timestamp {
	my ($add) = shift;
	return time + ($add || $DEFAULT_SECONDS);
}

sub validate_subject {
	my ($subject) = shift;
	
	if (!$subject) {
		die "No subject passed to validate_subject";
	}

	if (ref $subject) {
		die "The subject value must be a string containing a URL or 'mailto: address.'";
	}

	unless ($subject =~ m/^mailto\:/) {
		my $uri = URI->new($subject);
		if (!$uri->host) {
			die "VAPID subject is not a url or mailto: address";
		}
	}

	return $subject;
}

sub validate_public_key {
	my ($pub) = shift;

	if (!$pub) {
		die "No public key passed to validate_public_key";
	}

	if (ref $pub) {
		die "Vapid public key is must be a URL safe Base 64 encoded string";
	}

	$pub = decode_base64url($pub);

	if (length $pub != 65) {
		die "VAPID public key should be 65 bytes long when decoded.";
	}
	
	return $pub;
}

sub validate_private_key {
	my ($priv) = shift;

	if (!$priv) {
		die "No private key passed to validate_private_key";
	}

	if (ref $priv) {
		die "VAPID private key is must be a URL safe Base 64 encoded string";
	}

	$priv = decode_base64url($priv);
	
	if (length $priv != 32) {
		die "VAPID private key should be 32 bytes long when decoded.";
	}

	return $priv;
}

sub validate_expiration {
	my $expiration = shift;

	if (!$expiration || $expiration !~ m/^\d+$/) {
		die "expiration value must be a number";
	}

	my $max = generate_future_expiration_timestamp($MAX_DEFAULT_SECONDS);

	if ($expiration >= $max) {
    		die "expiration value is greater than maximum of 24 hours";
  	}
	
	return $expiration;
}

sub validate_subscription {
	my ($subscription) = @_;

	if (!$subscription) {
		die "No subscription passed to validate_subscription";
	}

	if (!ref $subscription || ref $subscription ne 'HASH') {
		die "Subscription must be a hash reference";
	}

	if (!$subscription->{endpoint}) {
		die "Subscription must have an endpoint";
	}

	my $uri = URI->new($subscription->{endpoint});
	if (!$uri->host) {
		die "Subscription endpoint is not a valid URL";
	}

	if (!$subscription->{keys}) {
		die "Subscription must have keys";
	}

	if (!$subscription->{keys}{p256dh}) {
		die "Subscription must have a p256dh key";
	}

	if (!$subscription->{keys}{auth}) {
		die "Subscription must have an auth key";
	}

	return $subscription;
}

sub encrypt_payload {
	my ($payload, $subscription) = @_;

	if (!defined $payload) {
		die "No payload passed to encrypt_payload";
	}

	validate_subscription($subscription);

	my $user_public_key = decode_base64url($subscription->{keys}{p256dh});
	my $user_auth = decode_base64url($subscription->{keys}{auth});

	my $salt = random_bytes(16);

	my $local_key = Crypt::PK::ECC->new();
	$local_key->generate_key('prime256v1');
	my $local_public_key = $local_key->export_key_raw('public');

	my $user_key = Crypt::PK::ECC->new();
	$user_key->import_key_raw($user_public_key, 'prime256v1');
	my $shared_secret = $local_key->shared_secret($user_key);

	my $auth_info = "Content-Encoding: auth\x00";
	my $prk = hkdf($shared_secret, $user_auth, 'SHA256', 32, $auth_info);

	my $context = "P-256\x00" 
		. pack('n', length($user_public_key)) . $user_public_key
		. pack('n', length($local_public_key)) . $local_public_key;

	my $cek_info = "Content-Encoding: aesgcm\x00" . $context;
	my $content_encryption_key = hkdf($prk, $salt, 'SHA256', 16, $cek_info);

	my $nonce_info = "Content-Encoding: nonce\x00" . $context;
	my $nonce = hkdf($prk, $salt, 'SHA256', 12, $nonce_info);

	my $padded_payload = pack('n', 0) . $payload;

	my ($ciphertext, $tag) = gcm_encrypt_authenticate(
		'AES',
		$content_encryption_key,
		$nonce,
		'',
		$padded_payload
	);

	return {
		ciphertext => $ciphertext . $tag,
		salt => $salt,
		local_public_key => $local_public_key
	};
}

sub build_push_request {
	my (%args) = @_;

	my $subscription = $args{subscription};
	my $payload = $args{payload};
	my $vapid_public = $args{vapid_public};
	my $vapid_private = $args{vapid_private};
	my $subject = $args{subject};
	my $ttl = $args{ttl} // 60;
	my $expiration = $args{expiration};
	my $enc = $args{enc};

	validate_subscription($subscription);

	my $endpoint = $subscription->{endpoint};
	my $uri = URI->new($endpoint);
	my $audience = $uri->scheme . '://' . $uri->host;

	my $vapid_headers = generate_vapid_header(
		$audience,
		$subject,
		$vapid_public,
		$vapid_private,
		$expiration,
		$enc
	);

	my $req = HTTP::Request->new(POST => $endpoint);
	$req->header(TTL => $ttl);
	$req->header(Authorization => $vapid_headers->{Authorization});

	if ($vapid_headers->{'Crypto-Key'}) {
		my $crypto_key = $vapid_headers->{'Crypto-Key'};

		if (defined $payload && length $payload) {
			my $encrypted = encrypt_payload($payload, $subscription);
			
			$crypto_key .= ';dh=' . encode_base64url($encrypted->{local_public_key});
			$req->header(Encryption => 'salt=' . encode_base64url($encrypted->{salt}));
			$req->header('Content-Encoding' => 'aesgcm');
			$req->header('Content-Type' => 'application/octet-stream');
			$req->content($encrypted->{ciphertext});
		}

		$req->header('Crypto-Key' => $crypto_key);
	} else {
		if (defined $payload && length $payload) {
			my $encrypted = encrypt_payload($payload, $subscription);
			
			$req->header('Crypto-Key' => 'dh=' . encode_base64url($encrypted->{local_public_key}));
			$req->header(Encryption => 'salt=' . encode_base64url($encrypted->{salt}));
			$req->header('Content-Encoding' => 'aesgcm');
			$req->header('Content-Type' => 'application/octet-stream');
			$req->content($encrypted->{ciphertext});
		}
	}

	$req->header('Content-Length' => length($req->content // ''));

	return $req;
}

sub send_push_notification {
	my (%args) = @_;

	my $ua = $args{ua} // LWP::UserAgent->new(timeout => 30);

	my $req = build_push_request(%args);
	my $resp = $ua->request($req);

	return {
		success => $resp->is_success,
		status => $resp->code,
		message => $resp->message,
		response => $resp
	};
}

1;

__END__

=head1 NAME

VAPID - Voluntary Application Server Identification

=head1 VERSION

Version 1.05

=cut

=head1 SYNOPSIS


	use VAPID qw/all/;

	my ($public, $private) = generate_vapid_keys();

	# Validate keys
	validate_public_key($public);
	validate_private_key($private);

	# Send a push notification
	my $subscription = {
		endpoint => $endpoint_from_browser,
		keys => {
			p256dh => $p256dh_from_browser,
			auth => $auth_from_browser
		}
	};

	my $result = send_push_notification(
		subscription => $subscription,
		payload => 'Hello World!',
		vapid_public => $public,
		vapid_private => $private,
		subject => 'mailto:email@lnation.org',
		ttl => 60
	);

	if ($result->{success}) {
		print "Notification sent!\n";
	}

	# Or build the request manually for more control
	my $req = build_push_request(
		subscription => $subscription,
		payload => 'Hello World!',
		vapid_public => $public,
		vapid_private => $private,
		subject => 'mailto:email@lnation.org'
	);

	# Or just generate headers (legacy)
	my $auth_headers = generate_vapid_header(
		'https://updates.push.services.mozilla.com',
		'mailto:email@lnation.org',
		$public,
		$private,
		time + 60
	);

=head1 DESCRIPTION

VAPID, which stands for Voluntary Application Server Identity, is a new way to send and receive website push notifications. Your VAPID keys allow you to send web push campaigns without having to send them through a service like Firebase Cloud Messaging (or FCM). Instead, the application server can voluntarily identify itself to your web push provider.

=head1 EXPORT

=head2 generate_vapid_keys 

Generates vapid private and public keys.
	
=head2 generate_vapid_header

Generates the Authorization and Crypto-Key headers that should be passed when making a request to push a notification.
	
=head2 generate_future_expiration_timestamp 

Generates a time that is in future based upon the number of seconds if passed, the default is 12 hours.

=head2 validate_subject 
	
Validate the subject.

=head2 validate_public_key 

Validate the public key.
	
=head2 validate_private_key 
	
Validate the private key. 

=head2 validate_expiration 

Validate the expiration key.

=head2 validate_subscription

Validate a push subscription object. Expects a hash reference with:
	
	{
		endpoint => 'https://fcm.googleapis.com/...',
		keys => {
			p256dh => '...',
			auth => '...'
		}
	}

=head2 encrypt_payload

Encrypt a message payload for web push using ECDH key agreement and AES-GCM.

	my $encrypted = encrypt_payload($message, $subscription);

=head2 build_push_request

Build a complete HTTP::Request object for sending a push notification.

	my $req = build_push_request(
		subscription => $subscription,
		payload => 'Hello World',
		vapid_public => $public,
		vapid_private => $private,
		subject => 'mailto:email@example.com',
		ttl => 60
	);

=head2 send_push_notification

Send a push notification and return the result.

	my $result = send_push_notification(
		subscription => $subscription,
		payload => 'Hello World',
		vapid_public => $public,
		vapid_private => $private,
		subject => 'mailto:email@example.com',
		ttl => 60
	);

	if ($result->{success}) {
		print "Notification sent!\n";
	}

=head1 Example

The following is pseudo code but it should get you started.

=head2 STEP 1 - generate private and public keys

	my ($public, $private) = generate_vapid_keys()

	$c->stash({
		VAPID_USER_PUBLIC_KEY => $public
	});

=head2 STEP 2 - main.js

	var publicKey = [% VAPID_USER_PUBLIC_KEY %];
        navigator.serviceWorker.getRegistrations().then(function (registrations) {
                navigator.serviceWorker.register('/service-worker.js').then(function (worker) {
                        console.log('Service Worker Registered');
			worker.pushManager.getSubscription().then(function(sub) {
				if (sub === null) {
				// Update UI to ask user to register for Push
					subscribeUser();
					console.log('Not subscribed to push service!');
				} else {
				// We have a subscription, update the database
					console.log('Subscription object: ', sub);
				}
			});
                });
        });

	function subscribeUser() {
		if ('serviceWorker' in navigator) {
			navigator.serviceWorker.ready.then(function(reg) {
				reg.pushManager.subscribe({
					userVisibleOnly: true,
					applicationServerKey: publicKey
				}).then(function(sub) {
				// We have a subscription, update the database
					console.log('Endpoint URL: ', sub.endpoint);
				}).catch(function(e) {
					if (Notification.permission === 'denied') {
						console.warn('Permission for notifications was denied');
					} else {
						console.error('Unable to subscribe to push', e);
					}
				});
			})
		}
	}

=head2 STEP 3 - service-worker.js

	self.addEventListener('push', function(e) {
		var body;
		if (e.data) {
			body = e.data.text();
		} else {
			body = 'Push message no payload';
		}

		var options = {
			body: body,
			icon: 'images/notification-flat.png',
			vibrate: [100, 50, 100],
			data: {
				dateOfArrival: Date.now(),
				primaryKey: 1
			},
		};
		e.waitUntil(
			self.registration.showNotification('Push Notification', options)
		);
	});

=head2 STEP 4 - manifest.json

Required for Chrome; Firefox works even without this file:

	{
		"short_name" : "Push",
		"name" : "Push Dashboard",
		"icons" : [
			{
			"src" : "/icon-144x144.png",
			"type" : "image/png",
			"sizes" : "144x144"
			}
		],
		"display" : "standalone",
		"start_url" : "/",
		"background_color" : "#fff",
		"theme_color" : "#fff",
		"scope" : "/"
	}	

=head2 STEP 5 - send the push notification

Using send_push_notification (recommended):

	use VAPID qw/all/;

	my $subscription = {
		endpoint => $subscription_url,
		keys => {
			p256dh => $user_p256dh_key,
			auth => $user_auth_key
		}
	};

	my $result = send_push_notification(
		subscription => $subscription,
		payload => 'Hello from VAPID!',
		vapid_public => $public,
		vapid_private => $private,
		subject => 'mailto:email@lnation.org',
		ttl => 60
	);

	if ($result->{success}) {
		print "Push message sent successfully.\n";
	} else {
		print "Push message failed: ", $result->{message}, "\n";
	}

=head2 STEP 5 (alternative) - build request manually

Using build_push_request for more control:

	use VAPID qw/all/;
	use LWP::UserAgent;

	my $subscription = {
		endpoint => $subscription_url,
		keys => {
			p256dh => $user_p256dh_key,
			auth => $user_auth_key
		}
	};

	my $req = build_push_request(
		subscription => $subscription,
		payload => 'Hello from VAPID!',
		vapid_public => $public,
		vapid_private => $private,
		subject => 'mailto:email@lnation.org',
		ttl => 60
	);

	my $ua = LWP::UserAgent->new;
	my $resp = $ua->request($req);

	if ($resp->is_success) {
		print "Push message sent successfully.\n";
	} else {
		print "Push message failed: ", $resp->as_string, "\n";
	}

=head2 STEP 5 (legacy) - generate headers only

For backward compatibility or custom implementations:

	my $notification_host = URI->new($subscription_url)->host;
	my $auth_headers = generate_vapid_header(
		"https://$notification_host",
		'mailto:email@lnation.org',
		$public,
		$private,
		time + 60
	);

	# Then manually construct HTTP request with headers
	# Note: This does not encrypt the payload

Curl from the command line (no payload):

	curl "{SUBSCRIPTION_URL}" --request POST --header "TTL: 60" --header "Content-Length: 0" --header "Authorization: {AUTHORIZATION_HEADER}" --header "Crypto-Key: {CRYPTO_KEY_HEADER}"

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-vapid at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=VAPID>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc VAPID


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=VAPID>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/VAPID>

=item * Search CPAN

L<https://metacpan.org/release/VAPID>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of VAPID
