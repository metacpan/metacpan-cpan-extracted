# This -*- perl -*- script writes the Makefile for UMLS::Interface
# (Last Updated 08/09/2004 -- Sid)
#
# Generates the Makefile for the UMLS::Interface Perl modules. 
#
# ----------------------------------------------------------------------

use 5.005;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $author4 = 'Siddharth Patwardhan <sidd@cs.utah.edu>';
my $author3 = 'Serguei Pakhomov <pakh0002@umn.edu>';
my $author2 = 'Ted Pedersen <tpederse@d.umn.edu>';
my $author1 = 'Bridget McInnes <bthomson@cs.umn.edu>';

WriteMakefile(
              'NAME'		  => 'UMLS::Interface',
              'VERSION_FROM'	  => 'lib/UMLS/Interface.pm',
              'PREREQ_PM'         => {'DBI' => '0',
				      'DBD::mysql' => '0',
				      'Digest::SHA1' => '2.12',
                                      'File::Spec' => '3.31',
                                      'File::Path' => '2.08'},
              'EXE_FILES'         => [("utils/getDUI.pl", "utils/removeConfigData.pl", "utils/findAncestors.pl", "utils/findLeastCommonSubsumer.pl", "utils/findPathToRoot.pl", "utils/findShortestPath.pl", "utils/getChildren.pl", "utils/getParents.pl", "utils/getCuiDef.pl", "utils/getExtendedDef.pl", "utils/getRelated.pl", "utils/getRelations.pl", "utils/getStDef.pl", "utils/getAssociatedTerms.pl", "utils/getAssociatedCuis.pl", "utils/findCuiDepth.pl", "utils/getSts.pl","utils/getSemanticGroup.pl", "utils/getSemanticRelation.pl", "utils/findDFS.pl", "utils/getTableNames.pl", "utils/getCuiList.pl", "utils/getIC.pl", "utils/getIntrinsicIC.pl", "utils/getStString.pl", "utils/findShortestPathLength.pl", "utils/getCompounds.pl", "utils/findNumberOfCloserConcepts.pl", "utils/findNumberTurns.pl")],
              'dist'              => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'},
              ($] >= 5.005 ?
               ('ABSTRACT_FROM'   => 'lib/UMLS/Interface.pm', # retrieve abstract from module
                'AUTHOR'          => "$author1, $author2, $author3, $author4") : ()));

