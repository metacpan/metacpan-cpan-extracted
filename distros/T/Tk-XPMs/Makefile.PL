use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tk::XPMs',
    VERSION_FROM      => 'lib/Tk/XPMs.pm', # finds $VERSION
    dist => {
      POSTOP => ('@echo "************  ATTENTION: are README, Changes und MANIFEST ok ? *******"'),
      TARFLAGS => '--create --verbose --mode=0755 --file',
    },
    
    PREREQ_PM         => {
      Tk => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tk/XPMs.pm', # retrieve abstract from module
       AUTHOR         => 'Lorenz Domke <lorenz.domke\@gmx.de>') : ()),
);
