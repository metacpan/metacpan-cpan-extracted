use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Unicode::SetAutomaton',
    VERSION_FROM      => 'lib/Unicode/SetAutomaton.pm', # finds $VERSION
    PREREQ_PM         => {
      'Graph'                   => 0,
      'Test::More'              => 0,
      'Set::IntSpan'            => 0,
      'Set::IntSpan::Partition' => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Unicode/SetAutomaton.pm', # retrieve abstract from module
       AUTHOR         => 'Bjoern Hoehrmann <bjoern@hoehrmann.de>') : ()),

    LICENSE           => 'perl',
    'dist'            => {
      PREOP     => 'chmod 600 Makefile.PL',
      TARFLAGS	=> '--group=cpan --owner=bjoern -cvf',
    },

);
