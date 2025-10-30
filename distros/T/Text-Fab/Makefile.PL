use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Text::Fab',
    VERSION_FROM      => 'lib/Text/Fab.pm', # finds $VERSION
    PREREQ_PM         => {FreezeThaw => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Text/Fab.pm', # retrieve abstract from module
       LICENSE        => 'perl_5',
       AUTHOR         => 'Ilya Zakharevich <ilyaz@cpan.com>') : ()),
);
