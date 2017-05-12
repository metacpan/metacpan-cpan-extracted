use Module::Build;
use strict;

my $build = Module::Build->new(
  create_makefile_pl => 'traditional',
  license            => 'perl',
  module_name        => 'Test::Expect',
  requires           => {
    'Class::Accessor::Chained::Fast'   => '0',
    'Expect::Simple' => '0',
  },
  test_requires      => {
    'Test::Builder'  => '0',
    'Test::More'     => '0',
    'Term::ReadLine' => '0',
  },
);
$build->create_build_script;
