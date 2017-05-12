
require 5.008_000;
use strict;
use warnings;
use Carp;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Text::Ngramize',
    VERSION_FROM => 'lib/Text/Ngramize.pm', # finds \$VERSION
    AUTHOR       => 'Jeff Kubina (jeff.kubina@gmail.com)',
    ABSTRACT     => 'Computes lists of n-grams of text.',
    PREREQ_PM    => {
                     # list of core modules used:

                     # list of installed modules used:
                     'Data::Dump' => '1.14',

                     # list of unknown modules used:
                    },
    LICENSE      => 'perl',
);

__END__
# Below are the automatically recommended values for PREREQ_PM.
    PREREQ_PM    => {
                     # list of core modules used:
                     'bytes' => '1.03',
                     'Carp' => '1.08',
                     'Encode' => '2.39',
                     'integer' => '1.00',
                     'strict' => '1.04',
                     'Test::More' => '0.94',
                     'vars' => '1.01',
                     'warnings' => '1.06',

                     # list of installed modules used:
                     'Data::Dump' => '1.15',
                     'Text::Ngramize' => '1.02',

                     # list of unknown modules used:
                     '5.008_000' => '0',
                    },