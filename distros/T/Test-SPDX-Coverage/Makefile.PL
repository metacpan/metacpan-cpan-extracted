use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Test::SPDX::Coverage',
    VERSION_FROM      => 'lib/Test/SPDX/Coverage.pm',
    PREREQ_PM         => {
                          'License::SPDX' => 0,
                          'Test::Builder' => 0,
                          'Test::More'    => 0,
                         },
    ABSTRACT_FROM     => 'lib/Test/SPDX/Coverage.pm',
    AUTHOR            => 'Michael R. Davis',
    LICENSE           => 'mit',
  'META_MERGE' => {
    'meta-spec' => {
      'version' => 2
    },
    'resources' => {
      'homepage' => 'https://github.com/mrdvt92/perl-Test-SPDX-Coverage',
      'bugtracker' => {
        'web' => 'https://github.com/mrdvt92/perl-Test-SPDX-Coverage/issues'
      },
      'repository' => {
        'type' => 'git',
        'url' => 'git@github.com:mrdvt92/perl-Test-SPDX-Coverage.git',
        'web' => 'https://github.com/mrdvt92/perl-Test-SPDX-Coverage.git'
      }
    }
  }
);
