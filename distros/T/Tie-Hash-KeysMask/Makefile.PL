use 5.008007;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tie::Hash::KeysMask',
    VERSION_FROM      => 'lib/Tie/Hash/KeysMask.pm', # finds $VERSION
    PREREQ_PM         => {'Tie::Hash::Create'=>0.01},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tie/Hash/KeysMask.pm', # retrieve abstract from module
       AUTHOR         => 'Josef Schoenbrunner <j.schoenbrunner@schule.at>') : (),
       ABSTRACT       => 'Control key aliasing by mask function, e.g. omit case of character distinction',
    )
  );
