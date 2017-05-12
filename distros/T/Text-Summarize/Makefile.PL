

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Text::Summarize',
    VERSION_FROM => 'lib/Text/Summarize.pm', # finds \$VERSION
    AUTHOR       => 'Jeff Kubina (jeff.kubina@gmail.com)',
    ABSTRACT     => 'Routine to compute summaries of text.',
    PREREQ_PM    => {
                     'Data::Dump' => '1.21',
                     'Lingua::EN::Sentence' => '0.25',
                     'Log::Log4perl' => '1.35',
                     'Text::Categorize::Textrank' => '0.51',
                     'Text::StemTagPOS' => '0.61',
                     'Test::Simple' => '0.44',
                    },
    LICENSE      => 'perl',
);
__END__
# Below are the automatically recommended values for PREREQ_PM.
    PREREQ_PM    => {
                     # list of core modules used:
                     'Getopt::Long' => '2.38',
                     'strict' => '1.04',
                     'Test::More' => '0.98',
                     'vars' => '1.01',
                     'warnings' => '1.09',

                     # list of installed modules used:
                     'Data::Dump' => '1.21',
                     'Lingua::EN::Sentence' => '0.25',
                     'Log::Log4perl' => '1.35',
                     'Text::Categorize::Textrank' => '0.51',
                     'Text::Categorize::Util' => '0.51',
                     'Text::StemTagPOS' => '0.61',
                     'Text::Summarize' => '0.50',
                     'Text::Summarize::En' => '0.50',

                     # list of unknown modules used:
                    },