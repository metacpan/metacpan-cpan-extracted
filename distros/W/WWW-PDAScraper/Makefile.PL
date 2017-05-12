
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'WWW::PDAScraper',
    VERSION_FROM => '',                  # finds \$VERSION
    AUTHOR   => 'John Horner (bounce@johnhorner.nu)',
    ABSTRACT =>
      'Class for scraping PDA-friendly content from websites',
    PREREQ_PM => {
        'Test::Simple'    => 0.44,
        'URI::URL'          => 5.03,
        'HTML::TreeBuilder' => 3.13,
        'HTML::Template'    => 2.7,
        'Carp'              => 1.01,
        'LWP::UserAgent'    => 2.033,
    },
);

