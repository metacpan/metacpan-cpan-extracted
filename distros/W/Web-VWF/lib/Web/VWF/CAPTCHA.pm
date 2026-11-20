package Web::VWF::CAPTCHA;

use strict;
use warnings;

use version; our $VERSION = version->declare('0.003.1');
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

=encoding utf8

=head1 NAME

Web::VWF::CAPTCHA - Check a Google reCAPTCHA answer

=head1 VERSION

Version 0.003.1

=head1 SYNOPSIS

	my $captcha = Web::VWF::CAPTCHA->new(site_key => $site, secret_key => $secret, logger => $logger);
	if($captcha->verify($info->param('g-recaptcha-response'), $ENV{'REMOTE_ADDR'})) {
		# a person
	}

=head1 DESCRIPTION

Used by L<Web::VWF> when a client has been shown the CAPTCHA page because it went
over the rate limit.  The keys are the C<recaptcha> settings, see
L<Web::VWF/CONFIGURATION>.

=head1 METHODS

=head2 new

Takes C<site_key> and C<secret_key>, both required, and optionally a C<logger>.
Croaks when either key is missing.

=head3 API SPECIFICATION

=head4 INPUT

	{
		site_key => { type => 'string' },
		secret_key => { type => 'string' },
		logger => { type => 'object', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'Web::VWF::CAPTCHA' }

=head2 verify

Asks Google whether the answer in C<$response_token> is a good one, with a
ten-second timeout.  The second argument is the client's address, which Google
is told and which is used in log messages.  Anything that goes wrong, such as no
token, no reply or a reply that cannot be read, is a failed verification and not
an error.

=head3 API SPECIFICATION

=head4 INPUT

	{ response_token => { type => 'string' }, remote_ip => { type => 'string', optional => 1 } }

=head4 OUTPUT

	{ type => 'boolean' }	# 1 or 0

=head2 get_site_key

Returns the site key, which the CAPTCHA page puts in the form.

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'string' }

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2010-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
