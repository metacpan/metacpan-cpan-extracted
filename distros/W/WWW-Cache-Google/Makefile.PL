use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'WWW::Cache::Google',
    'VERSION_FROM' => 'lib/WWW/Cache/Google.pm', # finds $VERSION
    'PREREQ_PM' => {
	'URI' => 0,
	'URI::Escape' => 0,
	'LWP::Simple' => 0,
    },
);
