use 5.016003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Win32::CheckDotNet',
    VERSION_FROM      => 'lib/Win32/CheckDotNet.pm', # finds $VERSION
    PREREQ_PM         => {
		# e.g., Module::Name => 1.1
		'ExtUtils::MakeMaker'	=> '6.76',
		'Moose'					=> '2.0604',
		'Win32API::Registry'	=> '0.30',
		'Win32::TieRegistry'	=> '0.26',
		'Log::Log4perl'			=> '1.42',
		
	},
	TEST_REQUIRES => {
		'Test::More'			=> '0.98',
		'Test::Pod'				=> '1.48',
		'Test::Pod::Coverage'	=> '1.08',
	},
	LICENSE		   		=> 'perl',
    ABSTRACT_FROM  		=> 'lib/Win32/CheckDotNet.pm', # retrieve abstract from module
    AUTHOR         		=> 'Alexander Becker <cf@pod.mail>',
	MIN_PERL_VERSION	=> '5.016003',
);
