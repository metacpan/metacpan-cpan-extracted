use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'			=>	'Tie::DB_FileLock',
    'VERSION_FROM'	=>	'DB_FileLock.pm', # finds $VERSION
	'dist'			=>	{ COMPRESS=>"gzip", SUFFIX=>"gz" },
);
