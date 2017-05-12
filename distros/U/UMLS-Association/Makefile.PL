# This -*- perl -*- script writes the Makefile for UMLS::Interface
# (Last Updated 08/09/2004 -- Sid)
#
# Generates the Makefile for the UMLS::Association Perl modules. 
#
# ----------------------------------------------------------------------

use 5.005;
use ExtUtils::MakeMaker;
my $author2 = 'Keith Herbert <herbertkb@vcu.edu>'; 
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.


my $author3 = 'Andriy Mulyar <andriy.mulyar@gmail.com>'; 
my $author2 = 'Keith Herbert <herbertkb@vcu.edu>'; 
my $author1 = 'Bridget McInnes <btmcinnes@vcu.edu';

WriteMakefile(
              'NAME'		  => 'UMLS::Association',
              'VERSION_FROM' => 'lib/UMLS/Association.pm',
              'PREREQ_PM'      => {'DBI' => '0',
				      'DBD::mysql' => '0',
                                      'Text::NSP' => '0', 
                                      'UMLS::Interface' => '0', 
                                      'File::Spec' => '3.31',
                                      'File::Path' => '2.08'},
              'EXE_FILES'         => [("utils/umls-association.pl", "utils/CUICollector.pl")], 
              'dist'              => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'},
    ($] >= 5.005 ?
     ('ABSTRACT_FROM'   => 'lib/UMLS/Association.pm', # retrieve abstract from module
      'AUTHOR'          => "$author1, $author2, $author3") : ()));

