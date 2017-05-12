use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tie::NumericRange',
    VERSION_FROM      => 'lib/Tie/NumericRange.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tie/NumericRange.pm', # retrieve abstract from module
       AUTHOR         => 'Michael Gregorowicz <mikeyg@hsd1.mi.comcast.net.>') : ()),
);
