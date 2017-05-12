# This -*- perl -*- script writes the Makefile for UMLS::Similarity
# (Last Updated 08/09/2004 -- Sid)
#
# Generates the Makefile for the UMLS::Similarity Perl modules. 
#
# ----------------------------------------------------------------------

use 5.005;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $author4 = 'Ying Liu <liux0395@umn.edu>';
my $author3 = 'Serguei Pakhomov <pakh0002@umn.edu>';
my $author2 = 'Ted Pedersen <tpederse@d.umn.edu>';
my $author1 = 'Bridget McInnes <bthomson@umn.edu>';

WriteMakefile(
              'NAME'		  => 'UMLS::SenseRelate',
              'VERSION_FROM'	  => 'lib/UMLS/SenseRelate.pm',
              'PREREQ_PM'         => {'UMLS::Interface' => '1.09',
				      'UMLS::Similarity'=> '1.05',
                                      'File::Spec' => '3.31',
                                      'Statistics::TTest' => '0.00', 
                                      'File::Path' => '2.08', 
                                      'XML::Twig' => '0.00'},
	      'EXE_FILES'         => [("utils/umls-targetword-senserelate.pl",
				       "utils/umls-allwords-senserelate.pl", 
				       "utils/umls-senserelate-evaluation.pl", 
				       "utils/umls-senserelate-ttest.pl", 
				       "External/scorer/score.pl", 
				       "converters/mm-xml2aw-xml.pl",
				       "converters/plain2mm-xml.pl")],
              'dist'              => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'},
              ($] >= 5.005 ?
               ('ABSTRACT_FROM'   => '', # retrieve abstract from module
                'AUTHOR'          => "$author1, $author2, $author3, $author4") : ()));

