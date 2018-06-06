use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'Text::Shingle',
   license => 'perl',
   create_makefile_pl => 'traditional',
  );

$build->create_build_script;
