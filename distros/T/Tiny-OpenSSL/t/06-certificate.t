use Test::More;
use Tiny::OpenSSL::Key;
use Tiny::OpenSSL::Subject;
use Tiny::OpenSSL::CertificateSigningRequest;

use_ok('Tiny::OpenSSL::Certificate');

my $cert = Tiny::OpenSSL::Certificate->new;

isa_ok( $cert, 'Tiny::OpenSSL::Certificate' );

my $key = Tiny::OpenSSL::Key->new;
$key->password('asdasdasd');
$key->create;

$cert->key($key);

my $subject = Tiny::OpenSSL::Subject->new(
    commonname          => 'test certificate',
    organizational_unit => 'Example Company',
    organization        => 'Example Department',
    locality            => 'Austin',
    state               => 'TX',
    country             => 'US'
);

$cert->subject($subject);

is( $cert->subject, $subject );

my $csr = Tiny::OpenSSL::CertificateSigningRequest->new(
    key     => $key,
    subject => $subject
);

$csr->create;

ok( $cert->self_sign($csr) );

# TODO: Will need to add a validate method to ensure this is an X509 cert
ok( $cert->file->lines > 0 );

done_testing;
