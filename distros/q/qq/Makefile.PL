use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'qq',
    VERSION_FROM      => 'lib/qq.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {'Crypt::Blowfish' => '0', 'Crypt::CBC' => '0', 'DBI' => '0', 'DBD::SQLite' => 0, 'POSIX' => '0'}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/qq.pm', # retrieve abstract from module
    AUTHOR            => 'pc <pc@>',
    EXE_FILES         => ['script/qq'],
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
