use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tk::VisualBrowser',
    VERSION_FROM      => 'lib/Tk/VisualBrowser.pm', # finds $VERSION
    PREREQ_PM         => {
      Tk => 804.027,
      Tk::XPMs => 1.03
    }, # e.g., Module::Name => 1.1
    dist => {
      POSTOP => ('@echo "************  ATTENTION: are README, Changes und MANIFEST ok ? *******"'),
      TARFLAGS => '--create --verbose --mode=0700 --file',
    },
    
    'PM' =>
    {
      'lib/Tk/VisualBrowser.pm' => '$(INST_LIBDIR)/VisualBrowser.pm',
      'lib/Tk/vis-empty.gif' => '$(INST_LIBDIR)/vis-empty.gif',
      'lib/Tk/vis-dummy.gif' => '$(INST_LIBDIR)/vis-dummy.gif',
      'lib/Tk/move.xbm' => '$(INST_LIBDIR)/move.xbm',
      'lib/Tk/move1.xbm' => '$(INST_LIBDIR)/move1.xbm',
      'lib/Tk/move_mask.xbm' => '$(INST_LIBDIR)/move_mask.xbm',
      'lib/Tk/move1_mask.xbm' => '$(INST_LIBDIR)/move1_mask.xbm',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tk/VisualBrowser.pm', # retrieve abstract from module
       AUTHOR         => 'Lorenz Domke <lorenz.domke\@gmx.de>') : ()),
);

print <<"EOT";

  Now you are ready to test and install Tk::VisualBrowser:

    make
    make test
    make install

  Please try also the test_it.pl script contained in this distribution ...

EOT
