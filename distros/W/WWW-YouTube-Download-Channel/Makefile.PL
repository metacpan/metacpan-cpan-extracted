

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'WWW::YouTube::Download::Channel',
    VERSION_FROM => 'lib/WWW/YouTube/Download/Channel.pm', # finds \$VERSION
    AUTHOR       => 'Hernan Lopes - hernanlopes <d0t> gmail ...',
    ABSTRACT     => 'Downloads all/every/some of the videos from any youtube user channel',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    'Perl6::Form' => 0,
                    'Moose' => 0,
                    'WWW::Mechanize' => 0,
                    'XML::XPath' => 0,
                    'IO::Socket::SSL' => 0,
                    'XML::XPath::XMLParser' => 0,
                    'WWW::YouTube::Download' => 0,
                    'LWP::Protocol::https' => 0,
                    'Mozilla::CA' => 0,
                    'DateTime' => 0,
                    },
);
