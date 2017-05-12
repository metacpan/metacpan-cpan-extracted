use 5.006001;
use ExtUtils::MakeMaker;
our $TKV = "804.027";
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tk::MiniCalendar',
    VERSION_FROM      => 'lib/Tk/MiniCalendar.pm', # finds $VERSION
    dist => {
      POSTOP => ('@echo "************  ATTENTION: are README, Changes und MANIFEST ok ? *******"'),
      TARFLAGS => '--create --verbose --mode=0700 --file',
    },
    PREREQ_PM         => {Tk::XPMs => 1.03,
                          Date::Calc => 5.0,
                          Tk => $TKV,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tk/MiniCalendar.pm', # retrieve abstract from module
       AUTHOR         => 'Lorenz Domke <lorenz.domke\@gmx.de>') : ()),
);

if ($Tk::VERSION < $TKV) {
  print <<"EOT";

 Your Tk version seems to be older than $TKV
 Tk::MiniCalendar will not use Tk::BrowseEntry for
 selection of month names ...
EOT

}
