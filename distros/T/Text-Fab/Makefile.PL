use 5.022000;
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
    TEST_REQUIRES => {
        'Test::Exception' => 0,	## Present (?) since Perl 5.18 (which bundles MakeMaker 6.90 >= 6.64)
    },
       AUTHOR         => 'Ilya Zakharevich <ilyaz@cpan.com>') : ()),
);
