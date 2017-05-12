use Test::More;

use Path::Tiny;
use Tiny::OpenSSL::Key;
use Tiny::OpenSSL::Subject;
use Tiny::OpenSSL::CertificateSigningRequest;

use_ok('Tiny::OpenSSL::CertificateAuthority');

can_ok( 'Tiny::OpenSSL::CertificateAuthority', 'subject' );
can_ok( 'Tiny::OpenSSL::CertificateAuthority', 'file' );
can_ok( 'Tiny::OpenSSL::CertificateAuthority', 'self_sign' );
can_ok( 'Tiny::OpenSSL::CertificateAuthority', 'sign' );

my $key = Tiny::OpenSSL::Key->new( password => 'RVcVbzkSMdyubL3AZxz7' );
$key->create;

my $subject = Tiny::OpenSSL::Subject->new(
    commonname          => 'test certificate authority',
    organizational_unit => 'Example Company',
    organization        => 'PKI Department',
    locality            => 'Austin',
    state               => 'TX',
    country             => 'US'
);

my $csr = Tiny::OpenSSL::CertificateSigningRequest->new(
    key     => $key,
    subject => $subject
);

$csr->create;

my $ca = Tiny::OpenSSL::CertificateAuthority->new(
    subject => $subject,
    key     => $key
);

ok( $ca->self_sign($csr) );

is( $ca->ascii, $ca->file->slurp );

done_testing;
