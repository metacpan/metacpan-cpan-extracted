package MyUtil;

use Sub::Install 0.90;

sub import {
	my $class = shift;
	my $caller = caller;

	for my $function (qw[is_tau_response should_ignore_response try_get]) {
		# Install check function in caller
		Sub::Install::install_sub({
			code => $function,
			into => $caller,
		});
	}

	return;
}

sub is_tau_response {
	my $response = shift;

	# This response came from Test::Override::UserAgent
	return defined $response->header('Client-Response-Source')
		&& $response->header('Client-Response-Source') eq 'Test::Override::UserAgent';
}
sub should_ignore_response {
	my $response = shift;

	# Ignore response if it was some kind of timeout
	return defined $response->header('Client-Warning')
		&& $response->header('Client-Warning') eq 'Internal response'
		&& $response->status_line =~ m{timeout}mosx;
}
sub try_get {
	my ($ua, $url, $tries) = @_;

	# Default to three tries
	$tries ||= 3;

	# Hold a valid response
	my $response;

	TRY:
	for my $i (3..$tries) {
		# Try and get the URL through our UA
		my $res = $ua->get($url);

		if (should_ignore_response($res)) {
			# This was a bad response, try again
			next TRY;
		}

		# Save this response
		$response = $res;
		last TRY;
	}

	return $response;
}

1;
