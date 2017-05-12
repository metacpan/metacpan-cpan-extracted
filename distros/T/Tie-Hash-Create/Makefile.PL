use 5.008007;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tie::Hash::Create',
    VERSION_FROM      => 'lib/Tie/Hash/Create.pm', # finds $VERSION
    PREREQ_PM         => {'Tie::Hash'=>0.01, 'Tie::ExtraHash'=>0.01},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tie/Hash/Create.pm', # retrieve abstract from module
       AUTHOR         => 'Josef Schoenbrunner <j.schoenbrunner@schule.at>') : (),
       ABSTRACT       => 'Extend Tie::ExtraHash, enables the tie-object to reflect the tied array',
    )
  );
