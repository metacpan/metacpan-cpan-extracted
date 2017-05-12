use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Win32::ASP',
    'VERSION_FROM' => 'ASP.pm', # finds $VERSION
	'dist' => {
		'COMPRESS' => 'gzip',
		'SUFFIX' => '.gz',
		'PREOP' => 'perl -MPod::Text -e "pod2text q(ASP.pm)" > README',
		},
	'AUTHOR' => 'Matt Sergeant and Bill Odom',
	'ABSTRACT' => 'Utility Functions for ASP Programming',
	'BINARY_LOCATION' => 'Win32-ASP.tar.gz',
);
