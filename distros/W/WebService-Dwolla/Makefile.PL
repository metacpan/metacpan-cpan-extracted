use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WebService::Dwolla',
    VERSION_FROM      => 'lib/WebService/Dwolla.pm', # finds $VERSION
    PREREQ_PM         => {
        'JSON'              => 2.15,
        'URI::Escape'       => 3.29,
        'IO::File'          => 1.14,
        'Data::Dumper'      => 2.124,
        'LWP::UserAgent'    => 5.833,
        'Crypt::SSLeay'     => 0.57,
        'Test::More'        => 0,
        'Digest::HMAC'      => 1.01
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WebService/Dwolla.pm', # retrieve abstract from module
       AUTHOR         => 'Chris Kloberdanz <klobyone@gmail.com>') : ()),
);
