use 5.010_001;
use strict;
use warnings;
use Module::Build;
use Config;

if (not $Config{useithreads}) {
	print STDERR "Can't use threads::lite without threading support";
	exit 0;
}

my $builder = Module::Build->new(
	module_name         => 'threads::lite',
	license             => 'perl',
	dist_author         => 'Leon Timmermans <leont@cpan.org>',
	dist_version_from   => 'lib/threads/lite.pm',
	configure_requires  => {
		'Module::Build' => 0,
	},
	build_requires => {
		'ExtUtils::CBuilder' => 0,
		'Module::Build' => 0,
		'Scalar::Util' => 0,
		'Test::More' => 0,
		'Test::Differences' => 0,
		'Test::Exception' => 0,
		'Time::HiRes' => 0,
	},
	requires            => {
		perl            => 5.010001,
		Exporter        => 5.57,
		Storable        => 2.05,
		experimental    => 0.003,
	},
	c_source            => 'src',
	PL_files            => {
		'src/tables.h.PL' => 'src/tables.h',
	},
    add_to_cleanup      => [ 'threads-lite-*' ],
	meta_merge => {
		resources       => {
			bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=threads-lite',
			repository  => 'http://github.com/Leont/threads-lite/tree',
		},
		keywords       => [ 'threads', 'channels' ],
	},
);

$builder->create_build_script();
