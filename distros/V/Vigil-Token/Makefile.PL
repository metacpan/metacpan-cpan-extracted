use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Vigil::Token',
    VERSION_FROM => 'lib/Vigil/Token.pm',
    AUTHOR       => 'Jim Melanson <jmelanson1965@gmail.com>',
    ABSTRACT     => 'Cryptographically secure, URL-safe token generator for OTPs, sessions, and custom codes.',
    LICENSE      => 'perl',
    PREREQ_PM => {
		'MIME::Base64' => 0,
		'Bytes::Random::Secure' => 0,
		'Math::BigInt' => 0
    },
    MIN_PERL_VERSION => '5.10.0',
);
