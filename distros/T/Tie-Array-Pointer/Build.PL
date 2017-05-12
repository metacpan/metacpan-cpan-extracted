use Module::Build;

my $builder = Module::Build->new (
  module_name    => 'Tie::Array::Pointer',
  license        => 'perl',

  requires       => {
    Tie::Array   => 0,
    DynaLoader   => 0,
  },

  build_requires => {
    'Test::More' => 0,
  },

  script_files   => [
  ],

  extra_compiler_flags => undef,
  extra_linker_flags   => undef,
  create_makefile_pl   => 'passthrough',
);

$builder->create_build_script();
