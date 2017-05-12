use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'YVDHOVE::System',
    VERSION_FROM      => 'lib/YVDHOVE/System.pm', # finds $VERSION
    PREREQ_PM         => { IO::CaptureOutput => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/YVDHOVE/System.pm', # retrieve abstract from module
       AUTHOR         => 'Yves Van den Hove <yvdhove@users.sourceforge.net>') : ()),
	dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },       
);
