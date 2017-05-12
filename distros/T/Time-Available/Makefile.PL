use 5.001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Time::Available',
    VERSION_FROM      => 'Available.pm', # finds $VERSION
    PREREQ_PM         => {
    	Carp => 0,
	Time::Local => 0,
	Test::More => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'Available.pm', # retrieve abstract from module
       AUTHOR         => 'Dobrica Pavlinusic <dpavlin@rot13.org>') : ()),
);
