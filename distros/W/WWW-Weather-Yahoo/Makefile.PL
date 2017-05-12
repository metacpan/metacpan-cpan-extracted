

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'WWW::Weather::Yahoo',
    VERSION_FROM => 'lib/WWW/Weather/Yahoo.pm', # finds \$VERSION
    AUTHOR       => 'Hernan Lopes (hernanlopes@gmail.com)',
    ABSTRACT     => 'Gets information from yahoo weather.',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'WWW::Mechanize' => 0,
                     'XML::XPath' => 0,
#                    'XML::XPath::XMLParser' => 0,
                    },
);
