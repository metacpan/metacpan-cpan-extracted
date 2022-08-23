use strict;
use warnings;
use Module::Build;
use Config;

if (not $Config{useithreads}) {
    print STDERR "Can't use threads::csp without threading support";
    exit 0;
}

my $builder = Module::Build->new(
  module_name  => 'Thread::Csp',
  c_source     => 'src',
  'build_requires' => {
    'Module::Build' => '0.28',
    'Test::More' => '0',
    'lib' => '0',
    'threads::shared' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.28'
  },
  'requires' => {
    'XSLoader' => '0',
    'perl' => '5.008001',
    'strict' => '0',
    'warnings' => '0'
  },
);

if ($^O ne 'MSWin32') {
	$builder->extra_compiler_flags('-pthread');
	$builder->extra_linker_flags('-pthread');
}

$builder->create_build_script();
