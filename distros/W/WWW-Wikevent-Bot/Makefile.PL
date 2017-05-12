use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'WWW::Wikevent::Bot',
    VERSION_FROM    => 'lib/WWW/Wikevent/Bot.pm',
    PREREQ_PM       => 
        { 
            'WWW::Mediawiki::Client' => 0.31,
            'Date::Parse' => 0,
            'Date::Format' => 0
        },
);

