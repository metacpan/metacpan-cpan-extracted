use strict;
use warnings;
use Module::Build;
use Config;

my %forbidden = map { ($_ => 1) } qw/MSWin32 VMS/;
if (not $Config{useithreads}) {
	print STDERR "Can't use threads::posix without threading support\n";
	exit 0;
}
if ($forbidden{$^O}) {
	print STDERR "Can't use threads::posix on non-unix\n";
	exit 0;
}

my $builder = Module::Build->new(
  module_name         => 'threads::posix',
  'build_requires' => {
    'Module::Build' => '0.28',
    'POSIX' => '0',
    'Test::More' => '0',
    'Thread::Queue' => '0',
    'Thread::Semaphore' => '0',
    'Thread::SigMask' => '0',
    'Time::HiRes' => '0',
    'perl' => '5.006'
  },
  'configure_requires' => {
    'Module::Build' => '0.28',
    'perl' => '5.006'
  },
  'requires' => {
    'XSLoader' => '0',
    'base' => '0',
    'perl' => '5.006',
    'strict' => '0',
    'threads' => '0',
    'warnings' => '0'
  },
);

$builder->create_build_script();
