use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Wx::SimplePlotter',
    VERSION_FROM      => 'SimplePlotter.pm', # finds $VERSION
    PREREQ_PM         => {Wx => 0.18,
		          Test::More => 0.0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'SimplePlotter.pm', # retrieve abstract from module
       AUTHOR         => 'Christian Renz <crenz@web42.com>') : ()),
);
