use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'swished',
	PREFIX			  => '/usr/local/swished',
	LIB				  => '/usr/local/swished/lib',
	EXE_FILES		=> [ 'cgi-bin/swished' ],
	INSTALLSCRIPT		  => '/usr/local/swished/cgi-bin',
    VERSION_FROM      => 'lib/SWISHED.pm', # finds $VERSION
    PREREQ_PM         => { "SWISH::API" => 0.0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SWISHED.pm', # retrieve abstract from module
       AUTHOR         => 'joshr <joshr@localdomain>') : ()),
);

