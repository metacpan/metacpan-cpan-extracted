# Makefile.PL for Tie::ShadowHash module.  -*- perl -*-

use ExtUtils::MakeMaker;

WriteMakefile (
    NAME         => 'Tie::ShadowHash',
    DISTNAME     => 'Tie-ShadowHash',
    ($] >= 5.005 ?
     (ABSTRACT   => 'Merge multiple data sources into a hash',
      AUTHOR     => 'Russ Allbery <rra@stanford.edu>') : ()),
    ($] >= 5.010 ?
     (LICENSE    => 'perl') : ()),
    VERSION_FROM => 'ShadowHash.pm',
    dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' }
);
