use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Text::AsciidocDown',
  VERSION_FROM => 'lib/Text/AsciidocDown.pm',
  ABSTRACT_FROM => 'lib/Text/AsciidocDown.pm',
  AUTHOR       => 'Sandor Patocs',
  LICENSE      => 'perl_5',
  MIN_PERL_VERSION => '5.016',
  EXE_FILES    => ['script/asciidoc-down'],
  PREREQ_PM    => {
    'Carp'          => 0,
    'Cwd'           => 0,
    'File::Basename' => 0,
    'File::Spec'    => 0,
    'File::Temp'    => 0,
    'Getopt::Long'  => 0,
    'Pod::Usage'    => 0,
    'version'       => 0.77,
  },
  TEST_REQUIRES => {
    'Test::More' => 0,
  },
  META_MERGE   => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/spatocs/asciidoc-down.git',
        web => 'https://github.com/spatocs/asciidoc-down',
      },
      bugtracker => {
        web => 'https://github.com/spatocs/asciidoc-down/issues',
      },
      license => ['https://dev.perl.org/licenses/'],
    },
    x_contributors => ['Sandor Patocs'],
  },
);