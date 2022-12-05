use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Tk::FileTree',
    AUTHOR           => q{Jim Turner <turnerjw784@yahoo.com>},
    VERSION_FROM     => 'lib/Tk/FileTree.pm',
    ABSTRACT_FROM    => 'lib/Tk/FileTree.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'File::Spec' => 0,
        'Encode' => 0,
        'Tk' => 0,
        'Tk::Tree' => 0,
        'Test::More' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Tk-FileTree-*' },
);
