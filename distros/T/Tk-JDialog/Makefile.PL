use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Tk::JDialog',
    AUTHOR           => q{Jim Turner <turnerjw784@yahoo.com>},
    VERSION_FROM     => 'lib/Tk/JDialog.pm',
    ABSTRACT_FROM    => 'lib/Tk/JDialog.pm',
    LICENSE          => 'lgpl_2_1',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
	  'Tk'      => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Tk-JDialog-*' },
);
