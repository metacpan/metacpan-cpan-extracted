require 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	   => 'Unicode::Map8',
    'VERSION_FROM' => 'Map8.pm',
    'LIBS'	   => [''],
    'DEFINE'	   => '-DPERL',
    'INC'	   => '',
    'OBJECT'       => q[Map8$(OBJ_EXT) map8x$(OBJ_EXT)],
    'EXE_FILES'    => [qw(umap)],
    'PREREQ_PM'    => {
	                 'Unicode::String' => 2.00,
		      },
    dist           => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
