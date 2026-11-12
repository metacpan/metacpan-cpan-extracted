package Web::VWF::CAPTCHA;

use strict;
use warnings;

use version; our $VERSION = version->declare('0.002.0');
use Carp qw(croak);
use LWP::UserAgent;
use JSON::MaybeXS;

sub new {
	my ($class, %args) = @_;

	# Checked one at a time: "die LIST" inside the hash below would swallow
	# every key after it, losing the secret and the logger
	my $site_key = $args{site_key} or croak('site_key required');
	my $secret_key = $args{secret_key} or croak('secret_key required');

	my $self = {
		site_key => $site_key,
		secret_key => $secret_key,
		logger => $args{logger},
	};

	return bless $self, $class;
}

sub verify {
	my ($self, $response_token, $remote_ip) = @_;

	return 0 unless $response_token;
	$remote_ip //= 'unknown';	# Only used in log messages

	my $ua = LWP::UserAgent->new(timeout => 10);

	my $response = $ua->post('https://www.google.com/recaptcha/api/siteverify', {
		secret => $self->{secret_key},
		response => $response_token,
		remoteip => $remote_ip,
	});

	unless ($response->is_success) {
		$self->{logger}->error("reCAPTCHA verification failed: " . $response->status_line) if $self->{logger};
		return 0;
	}

	# A malformed reply is a failed verification, not a crash
	my $result = eval { decode_json($response->decoded_content()) };
	if($@ || (ref($result) ne 'HASH')) {
		$self->{logger}->error("reCAPTCHA verification failed: unparsable reply from $remote_ip") if $self->{logger};
		return 0;
	}

	if ($result->{success}) {
		$self->{logger}->info("reCAPTCHA verification successful for $remote_ip") if $self->{logger};
		return 1;
	}

	$self->{logger}->warn("reCAPTCHA verification failed for $remote_ip: " . join(', ', @{$result->{'error-codes'} || []}))
		if $self->{logger};

	return 0;
}

sub get_site_key {
	my $self = $_[0];
	return $self->{site_key};
}

1;
