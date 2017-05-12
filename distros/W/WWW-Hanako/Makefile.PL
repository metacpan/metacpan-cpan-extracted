use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Hanako',
    VERSION_FROM      => 'lib/WWW/Hanako.pm', # finds $VERSION
    PREREQ_PM         => {
        'Test::More' => 0,
        'LWP::UserAgent' => 0,
        'WWW::Mechanize' => 0,
        'Web::Scraper' => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Hanako.pm', # retrieve abstract from module
       AUTHOR         => 'Tsukasa Hamano <hamano@klab.org>') : ()),
    LICENSE           => 'perl',
);
