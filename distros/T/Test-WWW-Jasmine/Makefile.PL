use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Test::WWW::Jasmine',
    VERSION_FROM      => 'lib/Test/WWW/Jasmine.pm',

    PREREQ_PM => {
        'WWW::Selenium' => '1.33',
    },

    ABSTRACT => 'Test JavaScript with Jasmine BDD framework from Perl',
    AUTHOR   => 'Alexander Tokarev <tokarev@cpan.org>',
    LICENSE  => 'perl',

    ($ExtUtils::MakeMaker::VERSION >= 6.46
        ? ( META_MERGE => {
                resources => {
                    bugtracker => 'http://github.com/nohuhu/Test-WWW-Jasmine/issues',
                    repository => 'http://github.com/nohuhu/Test-WWW-Jasmine',
                },
            },
        )
        : ()
    ),
);

