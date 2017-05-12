use 5.020002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Zwoelf::Hash::Union',
    VERSION_FROM      => 'lib/Zwoelf/Hash/Union.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'Test:Deep'   => 0.115,
        'List::Util'  => 1.38,
        'Hash::Merge' => 0.200,
        'Test::More'  => 1.001014,
        'Data::Dump'  => 1.22, 
    }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Zwoelf/Hash/Union.pm', # retrieve abstract from module
    AUTHOR            => 'Martin Gutsch <gutsch@zwoelf.net>',
    LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
