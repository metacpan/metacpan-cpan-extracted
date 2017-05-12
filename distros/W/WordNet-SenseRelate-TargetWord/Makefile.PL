# A -*- perl -*- script that generates the Makefile for installing
# WordNet::SenseRelate::TargetWord.
#

use 5.006;
use ExtUtils::MakeMaker;

my $author1 = 'Siddharth Patwardhan <sidd@cs.utah.edu>';
my $author2 = 'Satanjeev Banerjee <banerjee+@cs.cmu.edu>';
my $author3 = 'Ted Pedersen <tpederse@d.umn.edu>';

my @installable = ("disamb.pl", "wps2sk.pl", "disamb-gui.pl", "senserelate.pl");

WriteMakefile(
    NAME              => 'WordNet::SenseRelate::TargetWord',
    VERSION_FROM      => 'lib/WordNet/SenseRelate/TargetWord.pm',
    PREREQ_PM         => {WordNet::QueryData => 1.32, XML::Parser => 2.34, WordNet::Similarity => 0.13}, 
    EXE_FILES         => [ map "utils/$_", @installable ],
    dist              => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/WordNet/SenseRelate/TargetWord.pm',
       AUTHOR         => "$author1, $author2, $author3") : ())
);

