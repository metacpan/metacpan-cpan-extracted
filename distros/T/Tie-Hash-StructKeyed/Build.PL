use Module::Build;
my $build = Module::Build->new
  (
   module_name => 'Tie::Hash::StructKeyed',
   license => 'perl',
   requires => {
                'perl'           => '5.6.1',
                'YAML'   => 0,
               },
   build_requires => {
                'Test::More'  => 0,
               },
   create_readme => 1,
  );
$build->create_build_script;
