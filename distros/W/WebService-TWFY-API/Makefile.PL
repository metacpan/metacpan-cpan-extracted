

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'WebService::TWFY::API',
    VERSION_FROM => 'lib/WebService/TWFY/API.pm', # finds \$VERSION
    AUTHOR       => 'Spiros Denaxas (s [dot] denaxas [@] gmail [dot]com)',
    ABSTRACT     => 'API interface for TheyWorkForYou.com',
    PREREQ_PM    => {
                     'Test::Simple'    => 0.44,
                     'Test::Exception' => 0.24,
                     'HTTP::Request'   => 0,
                     'LWP::UserAgent'  => 0,
                     'Carp'            => 0,
                     'URI'             => 0,
                    },
);
