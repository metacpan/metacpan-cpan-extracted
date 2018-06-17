use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

my $author1 = 'Clint Cuffy <cuffyca@vcu.edu';
my $author2 = 'Bridget McInnes <btmcinnes@vcu.edu>';

WriteMakefile(
    'NAME'                => 'Word2vec::Interface',
    'VERSION_FROM'        => 'lib/Word2vec/Interface.pm',
    'PREREQ_PM' => {
        'Encode' => '2.86',
        'XML::Twig' => '3.49',
        'File::Type' => '0.22',
        'Class::Struct' => '0.64',
        'Text::Unidecode' => '1.27',
        'Sys::CpuAffinity' => '1.10',
        'IO::Uncompress::Gunzip' => '2.069',
    }, 

    'EXE_FILES'            => [("utils/Word2vec-Interface.pl")], 
    'dist'              => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'},
    ($] >= 5.005 ?
     ('ABSTRACT_FROM'   => 'lib/Word2vec/Interface.pm', 
      'AUTHOR'          => "$author1, $author2" ) : ())); 
 
