

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'WWW::Mechanize::Plugin::Web::Scraper',
    VERSION_FROM => 'lib/WWW/Mechanize/Plugin/Web/Scraper.pm', # finds \$VERSION
    AUTHOR       => 'Menno Blom (blom@cpan.org)',
    ABSTRACT     => 'Scrape the planet!',
    PREREQ_PM    => {
                     'Test::Simple'             => 0.44,
                     'Web::Scraper'             => 0.25,
                     'WWW::Mechanize'           => 0,
                     'WWW::Mechanize::Pluggable'=> 0.10,
                    },
);
