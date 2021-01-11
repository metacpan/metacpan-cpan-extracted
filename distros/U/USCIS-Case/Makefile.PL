require 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'USCIS::Case',
    VERSION_FROM      => 'lib/USCIS/Case.pm',
    MIN_PERL_VERSION  => 5.008008,
    PREREQ_PM         => {
        'LWP::UserAgent' => '6.02',
        'LWP::Protocol::https' => '6.02',
        'XML::LibXML' => '2.0132',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/meow-watermelon/USCIS-Case.git',
                web => 'https://github.com/meow-watermelon/USCIS-Case',
            },
            bugtracker => {
                web => 'https://github.com/meow-watermelon/USCIS-Case/issues',
            },
        },
    },
    ABSTRACT_FROM     => 'lib/USCIS/Case.pm',
    AUTHOR            => 'Hui Li <herdingcat@yahoo.com>',
    LICENSE           => 'perl',
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'USCIS-Case*' },
);
