use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME	=> 'ponfish',
    PMLIBDIRS	=> [ 'Ponfish', 'Ponfish/News', 'Ponfish/Menu'
		   ],
    EXE_FILES   => [
                    'ponfishr',
                    'ponfishd',
		    'pextract',
		    'ponfish',
	           ],
    VERSION_FROM => 'VERSION', # finds $VERSION
);
