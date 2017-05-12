=head1 PURPOSE

Tests that L<Web::ID::Certificate> is able to extract information from a
PEM-encoded certificate.

The majority of the tests are conducted on a certificate that I<< will
expire on 2013-06-21T11:49:45 >> however, it is believed that the nature
of these tests is such that they will continue to pass after the certificate
has expired. (No tests should be relying on it being a timely certificate.)
The situation may need reviewing in July 2013.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More tests => 18;
use Web::ID::Certificate;

my $cert = new_ok 'Web::ID::Certificate' => [pem => <<PEM];
-----BEGIN CERTIFICATE-----
MIIDwjCCAyugAwIBAgIBADANBgkqhkiG9w0BAQUFADCBiDELMAkGA1UEBhMCR0Ix
FDASBgNVBAgTC0Vhc3QgU3Vzc2V4MQ4wDAYDVQQHEwVMZXdlczEVMBMGA1UEChMM
VG9ieSBJbmtzdGVyMRUwEwYDVQQDEwxUb2J5IElua3N0ZXIxJTAjBgkqhkiG9w0B
CQEWFm1haWxAdG9ieWlua3N0ZXIuY28udWswHhcNMDkwNjIyMTE0OTQ1WhcNMTMw
NjIxMTE0OTQ1WjCBiDELMAkGA1UEBhMCR0IxFDASBgNVBAgTC0Vhc3QgU3Vzc2V4
MQ4wDAYDVQQHEwVMZXdlczEVMBMGA1UEChMMVG9ieSBJbmtzdGVyMRUwEwYDVQQD
EwxUb2J5IElua3N0ZXIxJTAjBgkqhkiG9w0BCQEWFm1haWxAdG9ieWlua3N0ZXIu
Y28udWswgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBANCO9ePkHf7wd12IV4pk
dWb6sMiaYwVe5epncwwARrxIoRfkwXrBkvV+bE9jjTQDODYNeLIPinnZEAfeIPEs
ahvFw88wA8gUEc0bjhH9BjlwJiWq9SzcGSm70CB11mkkBDkMfy2N/Jj6UeD3eWi4
7tCB23gcyHRcLzG/rJ2WD8lPAgMBAAGjggE4MIIBNDAdBgNVHQ4EFgQUsCURLq94
EfloWTu8vHlc/1qRWMAwgbUGA1UdIwSBrTCBqoAUsCURLq94EfloWTu8vHlc/1qR
WMChgY6kgYswgYgxCzAJBgNVBAYTAkdCMRQwEgYDVQQIEwtFYXN0IFN1c3NleDEO
MAwGA1UEBxMFTGV3ZXMxFTATBgNVBAoTDFRvYnkgSW5rc3RlcjEVMBMGA1UEAxMM
VG9ieSBJbmtzdGVyMSUwIwYJKoZIhvcNAQkBFhZtYWlsQHRvYnlpbmtzdGVyLmNv
LnVrggEAMAwGA1UdEwQFMAMBAf8wTQYDVR0RBEYwRIEWbWFpbEB0b2J5aW5rc3Rl
ci5jby51a4ENdGFpQGc1bi5jby51a4YbaHR0cDovL3RvYnlpbmtzdGVyLmNvLnVr
LyNpMA0GCSqGSIb3DQEBBQUAA4GBADrTzhHHsx2kox2rl1LLQvr7lCL0QJYoC/5B
NwTOr2DmtRsMbGLJsBoXylOmcBmKt6jwEjt8ZtpordY5WuCHdhQnQMPHVq7QedFN
67BP9knqFu7LV9dmqn12k0/I4b34/A0erLHTVzlj/E91OkASTf3M1ipGMcC8H97C
xQX4IrD3
-----END CERTIFICATE-----
PEM

is(
	$cert->not_before,
	'2009-06-22T11:49:45',
	'certificate not_before correct',
);

is(
	$cert->not_after,
	'2013-06-21T11:49:45',
	'certificate not_after correct',
);

ok(
	! $cert->timely( $cert->not_before->clone->subtract(days => 1) ),
	'not timely before not_before',
);

ok(
	$cert->timely( $cert->not_before ),
	'timely on not_before',
);

ok(
	$cert->timely( $cert->not_before->clone->add(days => 1) ),
	'timely after not_before',
);

ok(
	$cert->timely( $cert->not_after ),
	'timely on not_after',
);

ok(
	! $cert->timely( $cert->not_after->clone->add(days => 1) ),
	'not timely after not_after',
);

is(
	$cert->fingerprint,
	'f4651a0cd4efc7301103a7dfec983244dd47b190',
	'correct fingerprint',
);

ok(
	$cert->exponent eq '65537',
	'correct exponent'
);

(my $modulus = <<MOD)  =~ s/\D//g;
146454716751099837259538589121569684032917070750180889825346452
310909140079095101890533230320492369801087117742406223614892501
787774620864861679114505059424999743262559670390116085085948715
342933807186300265081435647527932300421122776861006014367973239
989185928655230008072818263686128144228920459652460693839
MOD

ok(
	$cert->modulus eq $modulus,
	'correct modulus'
);

isa_ok(
	$cert->subject_alt_names->[$_],
	'Web::ID::SAN',
	"SAN $_",
) for 0..2;

isa_ok(
	$cert->subject_alt_names->[0],
	'Web::ID::SAN::URI',
	"SAN 0",
);

isa_ok(
	$cert->subject_alt_names->[$_],
	'Web::ID::SAN::Email',
	"SAN $_",
) for 1..2;

is(
	$cert->subject_alt_names->[0]->value,
	'http://tobyinkster.co.uk/#i',
	'SAN 0 correct value',
);

