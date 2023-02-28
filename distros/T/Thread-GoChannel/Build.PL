use strict;
use warnings;
use Config;
use Module::Build;

if (not $Config{useithreads}) {
	print STDERR "Can't use threads::lite without threading support";
	exit 0;
}


my $builder = Module::Build->new(
  module_name         => 'Thread::GoChannel',
  'build_requires' => {
    'Module::Build' => '0.4004',
    'Test::Fatal' => '0',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.4004'
  },
  'requires' => {
    'XSLoader' => '0',
    'strict' => '0',
    'warnings' => '0'
  },
  c_source            => 'src',
);

$builder->create_build_script();
