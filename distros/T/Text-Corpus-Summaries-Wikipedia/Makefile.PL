

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

#01234567890123456789012345678901234567890123
#Creates corpora for summarization testing.

WriteMakefile(
    NAME         => 'Text::Corpus::Summaries::Wikipedia',
    VERSION_FROM => 'lib/Text/Corpus/Summaries/Wikipedia.pm', # finds \$VERSION
    AUTHOR       => 'Jeff Kubina (jeff.kubina@gmail.com)',
    ABSTRACT     => 'Creates corpora for summarization testing.',
    PREREQ_PM    => {
                     'Data::Dump' => '1.15',
                     'Date::Manip' => '6.11',
                     'File::Path' => '2.08',
                     'File::Slurp' => '9999.13',
                     'Forks::Super' => '0.30',
                     'HTML::TreeBuilder::XPath' => '0.11',
                     'Log::Log4perl' => '1.28',
                     'LWP::Simple' => '5.827',
                     'LWP::UserAgent' => '5.834',
                     'Statistics::Descriptive' => '2.6',
                     'XML::Code' => '0.4',
                     'XML::Simple' => '2.18',
                    },
    LICENSE      => 'perl',
);
