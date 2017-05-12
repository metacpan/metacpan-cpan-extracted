use Test::More;

use Tiny::OpenSSL::PKCS12;
use Tiny::OpenSSL::Subject;
use Tiny::OpenSSL::Certificate;
use Tiny::OpenSSL::Key;
use Tiny::OpenSSL::Subject;
use Tiny::OpenSSL::CertificateSigningRequest;

my $identity = 'test.example.com';

my $subject    = Tiny::OpenSSL::Subject->new( commonname => $identity );
my $key        = Tiny::OpenSSL::Key->new;
my $cert       = Tiny::OpenSSL::Certificate->new( subject => $subject );
my $passphrase = 'EaEcpG8XaHe2RBCpwysG';

$key->create;
$cert->key($key);

my $csr = Tiny::OpenSSL::CertificateSigningRequest->new(
    key     => $key,
    subject => $subject
);

$csr->create;
$cert->self_sign($csr);

my $p12 = Tiny::OpenSSL::PKCS12->new(
    certificate => $cert,
    key         => $key,
    passphrase  => $passphrase,
    identity    => $identity
);

isa_ok( $p12, 'Tiny::OpenSSL::PKCS12',
    'pkcs12 is a Tiny::OpenSSL::PKCS12 object' );

ok( $p12->create, 'pkcs12 created' );

ok( -e $p12->file && $p12->file->lines > 0, 'pkcs12 file created' );

done_testing;
