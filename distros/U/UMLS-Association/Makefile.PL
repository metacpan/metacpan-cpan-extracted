# This -*- perl -*- script writes the Makefile for UMLS::Interface
# (Last Updated 08/09/2004 -- Sid)
#
# Generates the Makefile for the UMLS::Association Perl modules. 
#
# ----------------------------------------------------------------------

use 5.005;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $author4 = 'Andriy Mulyar <andriy.mulyar@gmail.com>'; 
my $author3 = 'Keith Herbert <herbertkb@vcu.edu>'; 
my $author2 = 'Bridget McInnes <btmcinnes@vcu.edu';
my $author1 = 'Sam Henry <henryst@vcu.edu>';

WriteMakefile(
              'NAME'		  => 'UMLS::Association',
              'VERSION_FROM' => 'lib/UMLS/Association.pm',
              'PREREQ_PM'      => {  'Text::NSP' => '0', 
                                     'File::Spec' => '3.31',
                                      'File::Path' => '2.08',
                                      'Graph::Directed' => '0'},
              'EXE_FILES'         => [("utils/umls-association.pl", "utils/CUICollector.pl", "utils/umls-association-runDataSet.pl")], 
              'dist'              => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'},
    ($] >= 5.005 ?
     ('ABSTRACT_FROM'   => 'lib/UMLS/Association.pm', # retrieve abstract from module
      'AUTHOR'          => "$author1, $author4, $author2, $author3") : ()));

