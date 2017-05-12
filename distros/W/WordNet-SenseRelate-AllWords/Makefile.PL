# $Id: Makefile.PL,v 1.9 2009/05/27 21:26:53 kvarada Exp $

use strict;
use warnings;
use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'WordNet::SenseRelate::AllWords',
    VERSION_FROM      => 'lib/WordNet/SenseRelate/AllWords.pm', # finds $VERSION
    PREREQ_PM         => {'WordNet::Similarity' => 0.16},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WordNet/SenseRelate/AllWords.pm', # retrieve abstract from module
       AUTHOR         => 'Ted Pedersen <tpederse at d.umn.edu>') : ()),
    EXE_FILES         => ['utils/wsd.pl', 'utils/semcor-reformat.pl', 'utils/scorer2-format.pl', 'utils/scorer2-sort.pl','utils/wsd-experiments.pl','utils/allwords-scorer2.pl','utils/calculate-corpus-stats.pl','utils/extract-semcor-contentwords.pl','utils/extract-semcor-plaintext.pl','utils/convert-PENN-to-WN.pl'],
   # allows make dist to create .tar.gz with correct name/version
   'dist'             => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'},
   # allows for automatic creation of META.yml
   ($ExtUtils::MakeMaker::VERSION ge '6.30_00'?
   ('LICENSE' => 'gpl', ) : ()),
);
