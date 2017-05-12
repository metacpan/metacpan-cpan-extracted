use ExtUtils::MakeMaker;

WriteMakefile(
	NAME	  => 'Unix::MyPathToInc',
	VERSION_FROM => "MyPathToInc.pm",

	'dist'    => {COMPRESS => 'gzip -9f',
		      SUFFIX   => '.gz',
		      DIST_DEFAULT => 'all tardist',
		     },
);
