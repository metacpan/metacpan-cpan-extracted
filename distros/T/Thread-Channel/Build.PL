use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
  module_name         => 'Thread::Channel',
  'build_requires' => {
    'File::Spec' => '0',
    'IO::Handle' => '0',
    'IPC::Open3' => '0',
    'Module::Build' => '0.4004',
    'Test::Fatal' => '0',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.4004'
  },
  'requires' => {
    'Sereal' => '0',
    'XSLoader' => '0',
    'perl' => '5.008',
    'strict' => '0',
    'warnings' => '0'
  },
  c_source            => 'src',
);

$builder->create_build_script();
