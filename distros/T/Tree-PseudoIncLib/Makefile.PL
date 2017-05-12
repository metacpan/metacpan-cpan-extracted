use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tree::PseudoIncLib',
    'VERSION_FROM'	=> 'PseudoIncLib.pm', # finds $VERSION
    'PREREQ_PM'		=> {
				'Cwd'			=> '0',
				'File::Basename'	=> '0',
				'File::chdir'		=> '0',
				'File::Listing'		=> '0',
				'Log::Log4perl'		=> '0',
				'POSIX'			=> '0',
				'Test::Simple'		=> '0',
			   }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'PseudoIncLib.pm', # retrieve abstract from module
       AUTHOR     => 'Slava Bizyayev <slava@cpan.org>') : ()),
);
