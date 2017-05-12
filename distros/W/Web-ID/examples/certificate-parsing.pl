use 5.010;
use lib "../lib";
use lib "lib";
use Data::Dumper;
#use Moose ();
use Web::ID::Certificate;
use Web::ID::SAN;
use Web::ID::SAN::Email;
use Web::ID::SAN::URI;

my $cert = Web::ID::Certificate->new( pem => <<PEM );
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

local $Data::Dumper::Terse = 1;
say "Cert dates: ", $cert->not_before, " -- ", $cert->not_after;
say "Exponent: ", $cert->exponent;
say "Modulus: ", $cert->modulus;
say "Subject alt names: ", Dumper($cert->subject_alt_names);
say "Fingerprint: ", $cert->fingerprint;

