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
my $author3 = 'Serguei Pakhomov <pakh0002 at umn.edu>';
my $author2 = 'Ted Pedersen <tpederse@d.umn.edu>';
my $author1 = 'Bridget McInnes <bthomson@cs.umn.edu>';

WriteMakefile(
              'NAME'		  => 'UMLS::Similarity',
              'VERSION_FROM'	  => 'lib/UMLS/Similarity.pm',
              'PREREQ_PM'         => {'UMLS::Interface' => '1.43',
				      'Text::NSP' => '1.17', 
                                      'File::Spec' => '3.31',
                                      'File::Path' => '2.08', 
                                      'Lingua::Stem' => '0.84', 
				      'Text::OverlapFinder' => '0.02'},
	      'EXE_FILES'         => [("utils/umls-similarity.pl",
				       "utils/umls_similarity_server.pl",  
				       "utils/query-umls-similarity-webinterface.pl",  
				       "utils/vector-input.pl", 
				       "utils/spearmans.pl", 
				       "utils/create-icfrequency.pl", 
				       "utils/create-icpropagation.pl", 
                                       "utils/sim2r.pl",
				       "utils/SignificanceTesting.r")],
              'dist'              => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'},
              ($] >= 5.005 ?
               ('ABSTRACT_FROM'   => 'lib/UMLS/Similarity.pm', # retrieve abstract from module
                'AUTHOR'          => "$author1, $author2, $author3, $author4") : ()));

