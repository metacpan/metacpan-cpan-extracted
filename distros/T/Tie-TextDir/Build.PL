use strict;
use Module::Build;

my $build = Module::Build->new
  ( module_name => 'Tie::TextDir',
    dist_version_from => 'TextDir.pm',
    license => 'perl',
    requires => {
      'perl'       => '5.6.0',
      'strict'     => 0,
      'warnings'   => 0,
      'File::Basename' => 0,
      'File::Path' => 0,
      'File::Spec' => 0,
      'File::Temp' => 0,
      'File::Find::Iterator' => '0.4',
      'Symbol'     => 0,
      'Fcntl'      => 0,
      'Carp'       => 0,
    },
    build_requires => {
      'Test::More' => 0,
    },
	configure_requires => { 'Module::Build' => 0 },
    pm_files => { 'TextDir.pm' => 'lib/Tie/TextDir.pm' },
    cleanup_files => ['data'],
    create_makefile_pl => 'traditional',
    sign => 1,
  );
$build->create_build_script;
