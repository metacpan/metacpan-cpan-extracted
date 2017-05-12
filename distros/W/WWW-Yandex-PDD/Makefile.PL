use 5.008007;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'WWW::Yandex::PDD',
    PREREQ_PM => {
        'LWP::UserAgent' => 0, # any version will do
        'LWP::ConnCache' => 0,
        'XML::LibXML'    => 0,
        'URI::Escape'	 => 0,
    },
    (   $] >= 5.005
        ? ( ABSTRACT_FROM =>
                'lib/WWW/Yandex/PDD.pm',    # retrieve abstract from module
            AUTHOR =>
                'dctabuyz <dctabuyz@yandex.ru>, Andrei Lukovenko <aluck@cpan.org>'
            )
        : ()
    ),
    VERSION_FROM       => 'lib/WWW/Yandex/PDD.pm',
    ABSTRACT_FROM      => 'lib/WWW/Yandex/PDD.pm',
    LICENSE            => 'Artistic_2_0',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.010,
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
    BUILD_REQUIRES     => { 'Test::More' => 0, },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'WWW-Yandex-PDD-*' },
);
