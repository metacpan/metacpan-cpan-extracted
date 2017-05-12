use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name        => 'Tk::QuickTk',
      dist_abstract      => 'Simple, declarative syntax for a Perl/Tk GUI',
      license            => 'perl',
      requires           => { 'perl'           => '5.002',
                              'Exporter'       => 0,
                              'AutoLoader'     => 0,
                              'Carp'           => 0,
                              'Tk'             => 0,
                              'Text::TreeFile' => '0.39',
                              'FileHandle'     => 0,
                            },
      create_makefile_pl => 'traditional',
      (sign => 1),
    )->create_build_script;
