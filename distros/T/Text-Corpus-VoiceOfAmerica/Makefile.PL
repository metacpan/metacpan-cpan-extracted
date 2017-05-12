

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    LICENSE      => 'perl',
    NAME         => 'Text::Corpus::VoiceOfAmerica',
    VERSION_FROM => 'lib/Text/Corpus/VoiceOfAmerica.pm', # finds \$VERSION
    AUTHOR       => 'Jeff Kubina (jeff.kubina@gmail.com)',
    ABSTRACT     => 'Make a corpus of VOA articles for research.',
    PREREQ_PM    => {
                     # list of installed modules used:
                     'CHI' => '0.28',
                     'Data::Dump' => '1.15',
                     'Date::Manip' => '5.54',
                     'HTML::TreeBuilder::XPath' => '0.11',
                     'HTML::Encoding' => '0.60',
                     'Lingua::EN::Sentence' => '0.25',
                     'Log::Log4perl' => '1.24',
                     'LWP::Simple' => '5.827',
                     'Path::Class' => '0.16',
                     'Proc::Pidfile' => '1.005',
                     'URI::Escape' => '3.29',
                     'XML::LibXML' => '1.69',
                     'XML::RSS::Parser' => '2.11',
                    },
);
