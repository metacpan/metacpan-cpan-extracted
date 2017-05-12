use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Test::WWW::Selenium::HTML',
    AUTHOR         => q{Tom Harrison <cpan@apnic.net>},
    VERSION_FROM   => 'lib/Test/WWW/Selenium/HTML.pm',
    ABSTRACT_FROM  => 'lib/Test/WWW/Selenium/HTML.pm',
    LICENSE        => 'perl',
    META_MERGE => {
        resources => {
            repository => 'https://github.com/APNIC-net/p5-Test-WWW-Selenium-HTML'
        }
    },
    PL_FILES       => {},
    PREREQ_PM      => {
        'Params::Validate'              => '0',
        'HTTP::Daemon'                  => '0',
        'Test::WWW::Selenium'           => '0',
        'Test::Builder'                 => '0.90',
        'Time::HiRes'                   => '0',
        'XML::LibXML'                   => '0',
        # Build dependencies.
        'Test::Pod'                     => '0.95',
        'Test::More'                    => '0.90',
    },
    dist           => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
);
