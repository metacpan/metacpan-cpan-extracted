use Test::More;

use Tiny::OpenSSL::Key;
use Tiny::OpenSSL::Subject;

use_ok('Tiny::OpenSSL::CertificateSigningRequest');

my $key = Tiny::OpenSSL::Key->new( password => 'asdasd' );

$key->create;

my $subject = Tiny::OpenSSL::Subject->new(
    commonname          => 'test certificate',
    organizational_unit => 'Example Company',
    organization        => 'Example Department',
    locality            => 'Austin',
    state               => 'TX',
    country             => 'US'
);

my $csr = Tiny::OpenSSL::CertificateSigningRequest->new(
    key     => $key,
    subject => $subject
);

isa_ok( $csr, 'Tiny::OpenSSL::CertificateSigningRequest' );

ok( $csr->create );

is( $csr->ascii, $csr->file->slurp );

done_testing;
