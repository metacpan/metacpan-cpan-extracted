use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'WWW::Scraper::Delicious',
    VERSION_FROM  => 'lib/WWW/Scraper/Delicious.pm',
    PREREQ_PM     => { LWP::UserAgent => 0 },
);
