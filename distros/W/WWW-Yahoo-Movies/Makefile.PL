use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Yahoo::Movies',
    VERSION_FROM      => 'lib/WWW/Yahoo/Movies.pm', # finds $VERSION
    PREREQ_PM         => {
		LWP::Simple			=> 1.41,
		HTML::TokeParser	=> 2.30,
		Carp				=> 0,
	
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Yahoo/Movies.pm', # retrieve abstract from module
       AUTHOR         => 'Michael Stepanov <stepanov.michael@gmail.com>') : ()),
);
