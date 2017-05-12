package WWW::CSRF;

=pod

=head1 NAME

WWW::CSRF - Generate and check tokens to protect against CSRF attacks

=head1 SYNOPSIS

 use WWW::CSRF qw(generate_csrf_token check_csrf_token CSRF_OK);

Generate a token to add as a hidden <input> in all HTML forms:

 my $csrf_token = generate_csrf_token($username, "s3kr1t");

Then, in any action with side effects, retrieve that form field
and check it with:

 my $status = check_csrf_token($username, "s3kr1t", $csrf_token);
 die "Wrong CSRF token" unless ($status == CSRF_OK);

=head1 COPYRIGHT

Copyright 2013 Steinar H. Gunderson.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 DESCRIPTION

This module generates tokens to help protect against a website
attack known as Cross-Site Request Forgery (CSRF, also known
as XSRF).  CSRF is an attack where an attacker fools a browser into
make a request to a web server for which that browser will
automatically include some form of credentials (cookies, cached
HTTP Basic authentication, etc.), thus abusing the web server's
trust in the user for malicious use.

The most common CSRF mitigation is sending a special, hard-to-guess
token with every request, and then require that any request that
is not idempotent (i.e., has side effects) must be accompanied
with such a token.  This mitigation depends critically on the fact
that while an attacker can easily make the victim's browser
I<make> a request, the browser security model (same-origin policy,
or SOP for short) prevents third-party sites from reading the
I<results> of that request.

CSRF tokens should have at least the following properties:

=over

=item *
They should be hard-to-guess, so they should be signed
with some key known only to the server.

=item *
They should be dependent on the authenticated identity,
so that one user cannot use its own tokens to impersonate
another user.

=item *
They should not be the same for every request, or an
attack known as BREACH can use HTTP compression
to gradually deduce more and more of the token.

=item *
They should contain an (authenticated) timestamp, so
that if an attacker manages to learn one token, he or she
cannot impersonate a user indefinitely.

=back

WWW::CSRF simplifies the (simple, but tedious) work of creating and verifying
such tokens.

Note that resources that are protected against CSRF should also be protected
against a different attack known as clickjacking.  There are many defenses
against clickjacking (which ideally should be combined), but a good start is
sending a C<X-Frame-Options> HTTP header set to C<DENY> or C<SAMEORIGIN>.
See the L<Wikipedia article on clickjacking|http://en.wikipedia.org/wiki/Clickjacking>
for more information.

This module provides the following functions:

=over 4

=cut

use strict;
use warnings;
use Bytes::Random::Secure;
use Digest::HMAC_SHA1;
use constant {
	CSRF_OK => 0,
	CSRF_EXPIRED => 1,
	CSRF_INVALID_SIGNATURE => 2,
	CSRF_MALFORMED_TOKEN => 3,
};

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(generate_csrf_token check_csrf_token CSRF_OK CSRF_MALFORMED_TOKEN CSRF_INVALID_SIGNATURE CSRF_EXPIRED);
our $VERSION = '1.00';

=item generate_csrf_token($id, $secret, \%options)

This routine generates a CSRF token to send out to already authenticated users.
(Unauthenticated users generally need no CSRF protection, as there are no
credentials to impersonate.)

$id is the identity you wish to authenticate; usually, this would be a user name
of some sort.

$secret is the secret key authenticating the token.  This should be protected in
the same matter you would protect other server-side secrets, e.g. database
passwords--if this leaks out, an attacker can generate CSRF tokens at will.

The keys in %options are relatively esoteric and need generally not be set,
but currently supported are:

=over

=item *
C<Time>, for overriding the time value added to the token.  If this is not
set, the value of C<time()> is used.

=item *
C<Random>, for controlling the random masking value used to protect against
the BREACH attack.  If set, it must be exactly 20 random bytes; if not,
these bytes are generated with a call to L<Bytes::Random::Secure>.

=back

The returned CSRF token is in a text-only form suitable for inserting into
a HTML form without further escaping (assuming you did not send in strange
things to the C<Time> option).

=cut

sub generate_csrf_token {
	my ($id, $secret, $options) = @_;

	my $time = $options->{'Time'} // time;
	my $random = $options->{'Random'};

	my $digest = Digest::HMAC_SHA1::hmac_sha1($time . "/" . $id, $secret);
	my @digest_bytes = _to_byte_array($digest);

	# Mask the token to avoid the BREACH attack.
	if (!defined($random)) {
		$random = Bytes::Random::Secure::random_bytes(scalar @digest_bytes);
	} elsif (length($random) != length($digest)) {
		die "Given randomness is of the wrong length (should be " . length($digest) . " bytes)";
	}
	my @random_bytes = _to_byte_array($random);
	
	my $masked_token = "";
	my $mask = "";
	for my $i (0..$#digest_bytes) {
		$masked_token .= sprintf "%02x", ($digest_bytes[$i] ^ $random_bytes[$i]);
		$mask .= sprintf "%02x", $random_bytes[$i];
	}

	return sprintf("%s,%s,%d", $masked_token, $mask, $time);
}

=item check_csrf_token($id, $secret, $csrf_token, \%options)

This routine checks the integrity and age of the a token generated by
C<generate_csrf_token>.  The values of $id and $secret correspond to
the same parameters given to C<generate_csrf_token>, and $csrf_token
is the token to verify.  Also, you can set one or more of the following
options in %options:

=over

=item *
C<Time>, for overriding the time value used to check the age of the
token. If this is not set, the value of C<time()> is used.

=item *
C<MaxAge>, for setting a maximum age for the CSRF token in seconds.
If this is negative, I<no age checking is performed>, which is not
recommended.  The default value is a week, or 604800 seconds.

=back

This routine returns one of the following constants:

=over

=item *
C<CSRF_OK>: The token is verified correct.

=item *
C<CSRF_EXPIRED>: The token has an expired timestamp, but is otherwise
valid.

=item *
C<CSRF_INVALID_SIGNATURE>: The token is not properly authenticated;
either it was generated using the wrong secret, for the wrong user,
or it has been tampered with in-transit.

=item *
C<CSRF_MALFORMED_TOKEN>: The token is not in the correct format.

=back

In general, you should only allow the requested action if C<check_csrf_token>
returns C<CSRF_OK>.

Note that you are allowed to call C<check_csrf_token> multiple times with
e.g. different secrets.  This is useful in the case of key rollover, where
you change the secret for new tokens, but want to continue accepting old
tokens for some time to avoid disrupting operations.

=cut

sub check_csrf_token {
	my ($id, $secret, $csrf_token, $options) = @_;

	if ($csrf_token !~ /^([0-9a-f]+),([0-9a-f]+),([0-9]+)$/) {
		return CSRF_MALFORMED_TOKEN;
	}

	my $ref_time = $options->{'Time'} // time;

	my ($masked_token, $mask, $time) = ($1, $2, $3);
	my $max_age = $options->{'MaxAge'} // (86400*7);

	my @masked_bytes = _to_byte_array(pack('H*', $masked_token));
	my @mask_bytes = _to_byte_array(pack('H*', $mask));

	my $correct_token = Digest::HMAC_SHA1::hmac_sha1($time . '/' . $id, $secret);
	my @correct_bytes = _to_byte_array($correct_token);

	if ($#masked_bytes != $#mask_bytes || $#masked_bytes != $#correct_bytes) {
		# Malformed token (wrong number of characters).
		return CSRF_MALFORMED_TOKEN;
	}

	# Compare in a way that should make timing attacks hard.
	my $mismatches = 0;
	for my $i (0..$#masked_bytes) {
		$mismatches += $masked_bytes[$i] ^ $mask_bytes[$i] ^ $correct_bytes[$i];
	}
	if ($mismatches == 0) {
		if ($max_age >= 0 && $ref_time - $time > $max_age) {
			return CSRF_EXPIRED;
		} else {
			return CSRF_OK;
		}
	} else {
		return CSRF_INVALID_SIGNATURE;
	}
}

# Converts each byte in the given string to its numeric value,
# e.g., "ABCabc" becomes (65, 66, 67, 97, 98, 99).
sub _to_byte_array {
	return unpack("C*", $_[0]);
}

=back

=head1 SEE ALSO

Wikipedia has an article with more information on CSRF:

  L<http://en.wikipedia.org/wiki/Cross-site_request_forgery>

=cut

1;
