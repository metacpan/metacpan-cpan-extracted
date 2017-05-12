use Module::Build;

my $build = Module::Build->new
  ( module_name => 'Tie::TextDir',
    dist_version_from => 'TextDir.pm',
    license => 'perl',
    requires => {
		 'File::Spec' => 0,
		 'File::Temp' => 0,
		 'Symbol'     => 0,
		 'Fcntl'      => 0,
		 'Carp'       => 0,
		},
    build_requires => {
		       'Test' => 0,
		      },
    
    pm_files => { 'TextDir.pm' => 'lib/Tie/TextDir.pm' },
    cleanup_files => ['data'],
    create_makefile_pl => 'traditional',
    sign => 1,
  );
$build->create_build_script;
