

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'WWW::Alexa::API',
    VERSION_FROM => 'lib/WWW/Alexa/API.pm', # finds \$VERSION
    AUTHOR       => 'Rijvi Rajib (cpan@rij.co)',
    ABSTRACT     => 'A class implementation interface for querying Alexa.com for Traffic information.',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'LWP::UserAgent' => 6,
                     'XML::Hash::LX' => 0.0603
                    },
);
