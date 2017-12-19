use 5.024003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tribology::Lubricant',
    VERSION_FROM      => 'lib/Tribology/Lubricant.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    TEST_REQUIRES   => {
        "Try::Tiny" => 0,
    },
    ABSTRACT_FROM     => 'lib/Tribology/Lubricant.pm', # retrieve abstract from module
    AUTHOR            => 'Sherzod B. Ruzmetov <sherzodr@localdomain>',
    META_MERGE        => {
      resources => {
        repository => {
            type => 'git',
            url => 'git://github.com:sherzodr/perl-Tribology-Lubricant.git',
            web => 'https://github.com/sherzodr/perl-Tribology-Lubricant.git',
        },
      },
    },
    LICENSE           => 'mit',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
