use ExtUtils::MakeMaker;
WriteMakefile(
	      'EXE_FILES' => ['zinc-demos'],
	      'PMLIBDIRS' => [ qw( Tk/demos/zinc_pm Tk/demos/zinc_contrib_lib
				   Tk/demos/zinc_data Tk/demos/zinc_lib ) ],
      );
 
