use ExtUtils::MakeMaker;
WriteMakefile(
    NAME	     => 'Tie::EncryptedHash',
    VERSION      => '1.24',
    PREREQ_PM    => { 'Crypt::CBC' => 0, 
                      'Crypt::Blowfish' => 0, 
                      'Crypt::DES' => 0,
                    }
);
