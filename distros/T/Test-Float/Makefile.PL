use 5.008009;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Test::Float',
    VERSION_FROM      => 'lib/Test/Float.pm', # finds $VERSION
    PREREQ_PM         => { 
        PPI => 0.1, 
        'StupidMarkov' => 0.002, 
        'Acme::State' => 0.03, 
        'Devel::Caller' => 0.1, 
        'autobox::Core' => 1.0,
        # 'Data::Alias' => 0.1, 
    },
    ABSTRACT_FROM  => 'lib/Test/Float.pm', # retrieve abstract from module
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
