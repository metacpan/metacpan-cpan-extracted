use 5.018000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME               => 'credsman',
    VERSION_FROM       => 'lib/credsman.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    CONFIGURE_REQUIRES => { "ExtUtils::MakeMaker" => 0, },
    PREREQ_PM          => {'Test::More' => 0, 
                           'ExtUtils::MakeMaker' => '7.12',
                           'Types::Standard' => 0,
                           'Params::ValidationCompiler' => 0,
                           'Data::Dumper' => 0,
                           'Exporter'     => 0,
                          }, 
    ABSTRACT_FROM      => 'lib/credsman.pm', # retrieve abstract from module
    AUTHOR             => 'Rodrigo Agurto <rodagurto@aim.com>',
    LICENSE            => 'freebsd',
    #EXE_FILES          =>  ['example.pl'],
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
    LIBS               => ['-lgdi32 -lCredui'], # e.g., '-lm'
    DEFINE             => '', # e.g., '-DHAVE_SOMETHING'
    OPTIMIZE           => '-O3',
    TEST_REQUIRES      => {
                           'Net::FTP'   => 3,
                           'Test::More' => 0,
                           'ExtUtils::testlib' => 0,
                           'Params::ValidationCompiler' => 0,
                        },
);
