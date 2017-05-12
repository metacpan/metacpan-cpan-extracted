use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Unicode::Overload',
    VERSION_FROM      => 'lib/Unicode/Overload.pm', # finds $VERSION
    PREREQ_PM         => { Filter::Simple => 0.78 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Unicode/Overload.pm', # retrieve abstract from module
       AUTHOR         => 'Jeffrey Goff <jgoff@cpan.org>') : ()),
);
