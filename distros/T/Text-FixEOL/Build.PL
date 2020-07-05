use Module::Build;
my $build = Module::Build->new
      ( module_name    => 'Text::FixEOL',
        dist_author    => 'Jerilyn Franz <cpan@jerilyn.info>',
        dist_abstract  => 'Canonicalizes mixed convention EOL/EOF',
        license        => 'mit',
        requires => {
                'perl'             => '5.006',
                'warnings'         => 0,
                'Carp'             => 0,
                },
        test_requires => {
                'warnings'          => 0,
                'perl'              => '5.006',
                'Carp'              => 0,
                'Test::More'        => 0,
                'Test::NoWarnings'  => '1.04',
                },
        meta_merge => {
          'meta-spec' => { version => 2 },
           resources => {
              bugtracker => {
                   web  => 'https://github.com/JerilynFranz/perl-Text-FixEOL/issues',
               },
               homepage => 'https://github.com/JerilynFranz/perl-Text-FixEOL',
               repository => {
                   type => 'git',
                   url  => 'https://github.com/JerilynFranz/perl-Text-FixEOL.git',
                   web  => 'https://github.com/JerilynFranz/perl-Text-FixEOL',
               },
            },
        },
      )->create_build_script;
