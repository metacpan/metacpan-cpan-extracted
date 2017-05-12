use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
  module_name => 'Foo::Bar',
  build_requires => {
    'Test::More'          => '0.47',
    'Test::UseAllModules' => '0.10',
  },
  requires => {
    'File::Spec' => 0,
  }
);

$build->create_build_script;
