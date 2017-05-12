use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::Net::LDAP',
    AUTHOR              => q{Mahiro Ando <mahiro@cpan.org>},
    VERSION_FROM        => 'lib/Test/Net/LDAP.pm',
    ABSTRACT_FROM       => 'lib/Test/Net/LDAP.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Net::LDAP'  => '0.52',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-Net-LDAP-*' },
);
