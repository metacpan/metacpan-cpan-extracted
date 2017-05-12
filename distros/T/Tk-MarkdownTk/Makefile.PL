use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Tk::MarkdownTk',
    AUTHOR           => q{jimi <jimi@webu.co.uk>},
    VERSION_FROM     => 'lib/Tk/MarkdownTk.pm',
    ABSTRACT_FROM    => 'lib/Tk/MarkdownTk.pm',
    LICENSE          => 'Artistic_2_0',
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
        'Tk' => 5.0,
        'Tk::Markdown' => 0.05,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Tk-MarkdownTk-*' },
);
