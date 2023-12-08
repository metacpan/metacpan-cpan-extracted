use 5.016;

use strict;
use warnings;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  NAME => 'Test2::Formatter::YAMLEnhancedTAP',
  VERSION_FROM => 'lib/Test2/Formatter/YAMLEnhancedTAP.pm',
  PREREQ_PM => {
    'TAP::Harness' => 3.12
  },
  TEST_REQUIRES => {
    'Test::More' => '1.302087',
  },
  ABSTRACT_FROM => 'lib/Test2/Formatter/YAMLEnhancedTAP.pm',
  MIN_PERL_VERSION => '5.016000',
  META_MERGE => {
    dynamic_config => 0,
    "meta-spec" => {version => 2},
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/josegomezr/Test2-Formatter-YAMLEnhancedTAP.git',
        web => 'https://github.com/josegomezr/Test2-Formatter-YAMLEnhancedTAP',
      },
      bugtracker => {
        web => 'https://github.com/josegomezr/Test2-Formatter-YAMLEnhancedTAP/issues',
      },
    },
  },
  AUTHOR => 'Jose D. Gomez R. <1josegomezr@gmail.com>',
  LICENSE => 'perl',
);
