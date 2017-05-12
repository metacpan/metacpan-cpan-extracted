use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Test::Tail::Multi',
    VERSION_FROM      => 'lib/Test/Tail/Multi.pm', # finds $VERSION
    PREREQ_PM         => {'File::Tail' => 0,
			  'Test::Simple' => 0.98}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Joe McMahon <joe@corp.yahoo.com>') : ()),
);
