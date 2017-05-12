use Module::Build;
Module::Build->new(
  module_name => 'XML::Overlay',
  license => 'perl',
  create_makefile_pl => 'passthrough',
  requires => {
    'Test::More' => '0.0',
    'Class::XML' => '0.04',
  },
)->create_build_script;
