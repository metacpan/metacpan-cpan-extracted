use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'WWW::Finances::Bovespa',
    VERSION_FROM => 'lib/WWW/Finances/Bovespa.pm', # finds \$VERSION
    AUTHOR       => 'Hernan Lopes (hernanlopes@gmail.com)',
    ABSTRACT     => 'Reads stock options values from bovespa ( with 15min lag ).',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Moose' => 0,
                     'WWW::Mechanize' => 0,
                     'XML::XPath' => 0,
                    },
);
