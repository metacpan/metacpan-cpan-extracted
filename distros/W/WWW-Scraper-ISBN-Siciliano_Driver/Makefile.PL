use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Scraper::ISBN::Siciliano_Driver',
    VERSION_FROM      => 'lib/WWW/Scraper/ISBN/Siciliano_Driver.pm', # finds $VERSION
    PREREQ_PM         => {
        LWP                        => 5.805,
        HTTP::Request::Common      => 1.26,
        Test::More                 => 0.62,
        WWW::Scraper               => 3.05,
        WWW::Scraper::ISBN         => 0.25,
        WWW::Scraper::ISBN::Driver => 0.18,
        WWW::Scraper::ISBN::Record => 0.17,

    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Scraper/ISBN/Siciliano_Driver.pm', # retrieve abstract from module
       AUTHOR         => 'Joenio Costa <joenio@perl.org.br>') : ()),
);
