use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'             => 'Tk::Markdown',
    'AUTHOR'           => q{Alexander Becker <asb@cpan.org>},
    'VERSION_FROM'     => 'lib/Tk/Markdown.pm',
    'ABSTRACT_FROM'    => 'lib/Tk/Markdown.pm',
    'LICENSE'          => 'artistic_2',
    'PL_FILES'         => {},
    'MIN_PERL_VERSION' => 5.006,
    'CONFIGURE_REQUIRES' => {
        'ExtUtils::MakeMaker' => 6.46,
    },
    'BUILD_REQUIRES' => {
        'Test::More' => 0,
    },
    'PREREQ_PM' => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
        'Tk' => 5.0,
    },
    'dist' => {
        'COMPRESS' => 'gzip -9f',
        'SUFFIX' => 'gz',
    },
    'clean' => {
        'FILES' => 'Tk-Markdown-*',
    },
    'META_MERGE' => {
        'resources' => {
            'repository' => 'https://github.com/asb-capfan/Tk-Markdown',
        },
    },
);
