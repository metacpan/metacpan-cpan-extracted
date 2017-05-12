use ExtUtils::MakeMaker;
WriteMakefile(
	VERSION_FROM   => "rlib.pm",
	NAME      => "rlib",

	'dist'    => {COMPRESS => 'gzip -9f',
		      SUFFIX   => '.gz', 
		     },
);
