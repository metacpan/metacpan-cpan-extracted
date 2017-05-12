use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Value::Object',
    AUTHOR              => 'G. Wade Johnson <gwadej@cpan.org>',
    VERSION_FROM        => 'lib/Value/Object.pm',
    ABSTRACT_FROM       => 'lib/Value/Object.pm',
    LICENSE             => 'perl',
    MIN_PERL_VERSION    => 5.008,
    PL_FILES            => {},
#   EXE_FILES           => [ 'bin/prog' ],
    CONFIGURE_REQUIRES  => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'       => 0,
        'Test::Exception'  => 0,
        'File::Find'       => 0,
    },
    PREREQ_PM => {
        'parent'           => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Value-Object-*' },
    META_MERGE          => {
       'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/gwadej/value-object.git',
               web  => 'https://github.com/gwadej/value-object',
            },
       },
    },
    test               => {
        TESTS => 't/*.t xt/*.t',
    },
);
