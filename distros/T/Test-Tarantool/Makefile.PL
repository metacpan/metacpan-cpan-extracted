use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

unless ($^O eq 'linux') {
	warn "This is Linux only software\n";
	exit 0;
}

WriteMakefile(
    NAME             => 'Test::Tarantool',
    AUTHOR           => q{Anton Reznikov <a.reznikov@corp.mail.ru>},
    VERSION_FROM     => 'lib/Test/Tarantool.pm',
    ABSTRACT_FROM    => 'lib/Test/Tarantool.pm',
    LICENSE          => 'GPL',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test-Tarantool-*' },
);
