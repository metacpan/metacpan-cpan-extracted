#
# $Id: Makefile.PL,v 0.1 2008/07/01 17:56:27 dankogai Exp dankogai $
#
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tie::Expression',
    AUTHOR              => 'Dan Kogai <dankogai@dan.co.jp>',
    VERSION_FROM        => 'lib/Tie/Expression.pm',
    ABSTRACT_FROM       => 'lib/Tie/Expression.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tie-Expression-*' },
);
