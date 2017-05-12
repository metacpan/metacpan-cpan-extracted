# $Id: Makefile.PL,v 1.4 2008/03/22 02:13:00 tpederse Exp $
use strict;
use warnings;

use 5.006;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WordNet::SenseRelate::WordToSet',
    VERSION_FROM      => 'lib/WordNet/SenseRelate/WordToSet.pm', # finds $VERSION
    PREREQ_PM         => {'WordNet::QueryData' => 1.37,
		          'WordNet::Similarity' => 0.08},
    EXE_FILES         => ['bin/wordtoset.pl'],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WordNet/SenseRelate/WordToSet.pm', # retrieve abstract from module
       AUTHOR         => 'Ted Pedersen <tpederse at d.umn.edu>') : 
()),    # allows make dist to create .tar.gz with correct name/version
   'dist'             => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'},
   # allows for automatic creation of META.yml
   ($ExtUtils::MakeMaker::VERSION ge '6.30_00'?
   ('LICENSE' => 'gpl', ) : ()),

);
