use 5.022002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WG::Status',
    VERSION_FROM      => 'lib/WG/Status.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/WG/Status.pm', # retrieve abstract from module
    AUTHOR            => 'Joey Kelly <joey@joeykelly.net>',
    LICENSE           => 'gpl',
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
