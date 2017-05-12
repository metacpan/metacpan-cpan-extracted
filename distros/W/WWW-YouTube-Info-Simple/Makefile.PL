use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::YouTube::Info::Simple',
    VERSION_FROM      => 'lib/WWW/YouTube/Info/Simple.pm', # finds $VERSION
    PREREQ_PM         => {WWW::YouTube::Info => 0.05}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/YouTube/Info/Simple.pm', # retrieve abstract from module
       AUTHOR         => 'east') : ()),
);
