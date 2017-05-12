#
# $Id: Makefile.PL,v 0.2 2012/08/09 19:13:00 dankogai Exp dankogai $
#
use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Tie::Array::Lazy',
    AUTHOR        => 'Dan Kogai <dankogai@dan.co.jp>',
    VERSION_FROM  => 'lib/Tie/Array/Lazy.pm',
    ABSTRACT_FROM => 'lib/Tie/Array/Lazy.pm',
    LICENSE       => 'perl',
    PL_FILES      => {},
    PREREQ_PM     => { 'Test::More' => 0, },
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Tie-Array-Lazy-*' },
);
