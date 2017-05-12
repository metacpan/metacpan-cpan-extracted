
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Text::Corpus::NewYorkTimes',
    LICENSE      => 'perl',
    VERSION_FROM => 'lib/Text/Corpus/NewYorkTimes.pm', # finds \$VERSION
    AUTHOR       => 'Jeff Kubina (jeff.kubina@gmail.com)',
    ABSTRACT     => 'Interface to New York Times corpus.',
    PREREQ_PM    => {
                     'Data::Dump' => '1.15',
                     'Date::Manip' => '5.54',
                     'Log::Log4perl' => '1.24',
                     'Path::Class' => '0.16',
                     'XML::LibXML' => '1.69',
                     'XML::LibXML::XPathContext' => '1.69',
                    },
);

__END__
# Below are the automatically recommended values for PREREQ_PM.
    PREREQ_PM    => {
                     # list of core modules used:
                     'File::Find' => '1.10',
                     'File::Spec::Functions' => '3.30',
                     'File::Temp' => '0.22',
                     'strict' => '1.03',
                     'Test::More' => '0.94',
                     'vars' => '1.01',
                     'warnings' => '1.05',

                     # list of installed modules used:
                     'Data::Dump' => '1.15',
                     'Date::Manip' => '5.54',
                     'Log::Log4perl' => '1.24',
                     'Path::Class' => '0.16',
                     'XML::LibXML' => '1.69',
                     'XML::LibXML::XPathContext' => '1.69',

                     # list of unknown modules used:
                    },