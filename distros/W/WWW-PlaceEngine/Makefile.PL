use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::PlaceEngine',
    VERSION_FROM      => 'lib/WWW/PlaceEngine.pm', # finds $VERSION
    PREREQ_PM         => {
                             Readonly => 0,
                             JSON =>     0,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/PlaceEngine.pm', # retrieve abstract from module
       AUTHOR         => 'OHTSUKA Ko-hei <nene@kokogiko.net>') : ()),
);
