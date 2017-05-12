

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Text::Corpus::Inspec',
    LICENSE      => 'perl',
    VERSION_FROM => 'lib/Text/Corpus/Inspec.pm', # finds \$VERSION
    AUTHOR       => 'Jeff Kubina (jeff.kubina@gmail.com)',
    ABSTRACT     => 'Interface to Inspec abstracts corpus.',
    PREREQ_PM    => {
                     'Data::Dump' => '1.15',
                     'File::Slurp' => '9999.13',
                     'Lingua::EN::Sentence' => '0.25',
                     'Log::Log4perl' => '1.26',
                    },
);

__END__
# Below are the automatically recommended values for PREREQ_PM.
    PREREQ_PM    => {
                     # list of core modules used:
                     'Carp' => '1.08',
                     'ExtUtils::MakeMaker' => '6.54',
                     'File::Find' => '1.12',
                     'File::Spec::Functions' => '3.30',
                     'File::Temp' => '0.22',
                     'strict' => '1.04',
                     'Test::More' => '0.94',
                     'vars' => '1.01',
                     'warnings' => '1.06',

                     # list of installed modules used:
                     'Data::Dump' => '1.15',
                     'File::Slurp' => '9999.13',
                     'Lingua::EN::Sentence' => '0.25',
                     'Log::Log4perl' => '1.26',
                     'Text::Corpus::Inspec' => '1.0',
                     'Text::Corpus::Inspec::Document' => '1.0',

                     # list of unknown modules used:
                    },