use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Text::Index',
    VERSION_FROM      => 'lib/Text/Index.pm', # finds $VERSION
    PREREQ_PM         => {
	    Params::Util => '0',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Text/Index.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Müller <modules at steffen-mueller dot net>') : ()),
);
