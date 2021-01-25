use 5.022001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Text::Unmunch',
    VERSION_FROM      => 'lib/Text/Unmunch.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Text/Unmunch.pm', # retrieve abstract from module
    AUTHOR            => 'Eleonora <eleonora46@gmx.net>',
    LICENSE           => 'perl',
    TEST_REQUIRES     => {
                           'iren.dic'  => 0,
                           'en_US.aff' => 0,
                         },
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
