use ExtUtils::MakeMaker;
WriteMakefile(
    NAME                => 'WWW::Mechanize::Pliant',
    AUTHOR              => 'Boris Reitman <boris.reitman@gmail.com>',
    VERSION_FROM        => 'lib/WWW/Mechanize/Pliant.pm',
    ABSTRACT_FROM       => 'lib/WWW/Mechanize/Pliant.pm',
    PREREQ_PM           => {
        'WWW::Mechanize' => '1.00',
        'Test::More' => '0.47',
    },
    clean => { FILES => 'WWW-Mechanize-Pliant-*' },
);
