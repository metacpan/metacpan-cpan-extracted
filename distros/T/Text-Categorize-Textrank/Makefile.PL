
require 5.006_000;
use strict;
use warnings;
use Carp;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Text::Categorize::Textrank',
    VERSION_FROM => 'lib/Text/Categorize/Textrank.pm', # finds \$VERSION
    AUTHOR       => 'Jeff Kubina (jeff.kubina@gmail.com)',
    ABSTRACT     => 'Method to rank potential keywords of text.',
    LICENSE       => 'perl',
    PREREQ_PM    => {
                     # list of installed modules used:
                     'Data::Dump' => '1.15',
                     'Graph' => '0.91',
                     'Graph::Centrality::Pagerank' => '1.04',
                     'Log::Log4perl' => '1.25',
                     'Text::StemTagPOS' => '0.60',
                    },
);

__END__
# Below are the automatically recommended values for PREREQ_PM.
    PREREQ_PM    => {
                     # list of core modules used:
                     'diagnostics' => '1.19',
                     'strict' => '1.04',
                     'Test::More' => '0.96',
                     'utf8' => '1.08',
                     'vars' => '1.01',
                     'warnings' => '1.09',

                     # list of installed modules used:
                     'Data::Dump' => '1.17',
                     'Graph' => '0.94',
                     'Graph::Centrality::Pagerank' => '1.05',
                     'Log::Log4perl' => '1.29',
                     'Text::Categorize::Textrank' => '.90',
                     'Text::Categorize::Textrank::En' => '0.90',
                     'Text::Categorize::Util' => '0.01',
                     'Text::StemTagPOS' => '1.00',

                     # list of unknown modules used:
                    },