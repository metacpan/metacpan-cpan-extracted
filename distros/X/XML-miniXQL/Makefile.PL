use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'XML::miniXQL',
		DIR	=> ['Parser'],
		'VERSION_FROM' => 'miniXQL.pm', # finds $VERSION
	'AUTHOR'	=> 'Matt Sergeant',
	'dist'		=> {'COMPRESS' => 'gzip', 'SUFFIX' => '.gz'},
);
