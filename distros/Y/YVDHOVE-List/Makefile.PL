use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'YVDHOVE::List',
    VERSION_FROM      => 'lib/YVDHOVE/List.pm', # finds $VERSION
    PREREQ_PM         => { Tie::IxHash => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/YVDHOVE/List.pm', # retrieve abstract from module
       AUTHOR         => 'Yves Van den Hove <yvdhove@users.sourceforge.net>') : ()),
	dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },       
);
