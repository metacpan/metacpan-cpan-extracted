

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'WWW::Leech::Parser',
    VERSION_FROM => 'lib/WWW/Leech/Parser.pm', # finds \$VERSION
    AUTHOR       => 'Dmitry Selverstov ( jaredspb@cpan.org)',
    ABSTRACT     => 'HTML Page parser used by WWW::Leech::Walker',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'HTML::TreeBuilder::XPath' => 0.14
                    },
);
