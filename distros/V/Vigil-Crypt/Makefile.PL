use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Vigil::Crypt',
    VERSION_FROM => 'lib/Vigil/Crypt.pm',
    AUTHOR       => 'Jim Melanson <jmelanson1965@gmail.com>',
    ABSTRACT     => 'Encryption and Hashing wrapper for ChaCha20-Poly1305 and Argon2',
    LICENSE      => 'perl',
    PREREQ_PM => {
		'Time::Local'                 => 0,
		'Bytes::Random::Secure'       => 0,
		'Crypt::AuthEnc::ChaCha20Poly1305' => 0,
		'Digest::SHA'                 => 0,
		'Crypt::Argon2'               => 0
    },
    MIN_PERL_VERSION => '5.10.0',
    TEST_REQUIRES => {
          'Test::More'    => 1.001014,
    },
);
