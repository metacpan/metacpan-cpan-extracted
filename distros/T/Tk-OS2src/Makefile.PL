use ExtUtils::MakeMaker;
WriteMakefile(
	NAME		=> 'Tk::OS2src',
	VERSION_FROM	=> 'Tk/OS2src.pm',
	'dist'		=> {
				COMPRESS => 'gzip -9f',
				SUFFIX   => '.gz', 
				DIST_DEFAULT => 'all zipdist',
			   },

);
