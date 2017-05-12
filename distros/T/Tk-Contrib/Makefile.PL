use ExtUtils::MakeMaker;

WriteMakefile (
	'NAME'		=> 'Tk::Contrib',
	'DISTNAME'	=> 'Tk-Contrib',
	'VERSION'	=> '0.07',

	'dist'		=> { 'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz' },
);

