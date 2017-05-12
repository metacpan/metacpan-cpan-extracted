#!/usr/bin/perl

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'ptk',
    DISTNAME     => 'ptkFAQ',
    VERSION_FROM => 'ptkFAQ.pm',
#    VERSION_FROM => 'ptkFAQ.html', # alas "$VERSION = '0.05';#<BR>" 
#                                   # not optimal html/newsheader.
    NORECURS     => 'true',
    dist         => { COMPRESS => "gzip -9f" },
);
