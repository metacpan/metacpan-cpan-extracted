use ExtUtils::MakeMaker;

use strict;

WriteMakefile(
  'NAME'	   => 'bare',
  'VERSION_FROM'   => 'bare.pm',
  $ExtUtils::MakeMaker::VERSION > 6.55
      ? ( 'BUILD_REQUIRES' => { 'Test::More' => 0 } )
      : ( 'PREREQ_PM'      => { 'Test::More' => 0 } ),

  'dist'	=> { COMPRESS => 'gzip -9', SUFFIX => 'gz' },
);
