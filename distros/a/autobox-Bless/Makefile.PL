use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'autobox::Bless',
    VERSION_FROM      => 'lib/autobox/Bless.pm', # finds $VERSION
    PREREQ_PM         => {
        'Devel::Caller' => 2.05,
        'autobox' => 2.70,
        'Devel::Gladiator' => 0.01,
        'Data::Dumper' => 0.001,
        'Scalar::Util' => 0.001,
        'Devel::Peek' => 1.04,
    },
    ABSTRACT_FROM  => 'lib/autobox/Bless.pm', # retrieve abstract from module
    AUTHOR         => 'Scott Walters <scott@slowass.net>',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.46',                       # for META_MERGE
    },
    META_MERGE => {
        resources => {
            bugtracker => 'mailto:scott@slowass.net',
            repository => 'http://github.com/scrottie/autobox-Bless',
        }
    },   

);
