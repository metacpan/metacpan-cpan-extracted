use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'ULID::Tiny',
	VERSION_FROM     => 'lib/ULID/Tiny.pm',
	ABSTRACT_FROM    => 'lib/ULID/Tiny.pm',
	AUTHOR           => 'Scott Baker',
	LICENSE          => 'perl_5',
	MIN_PERL_VERSION => '5.016',
	PREREQ_PM        => {
		'Crypt::SysRandom' => '0.007',
		'Time::HiRes'      => 0,
	},
	TEST_REQUIRES => {
		'Test::More' => '0.88',
	},
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources   => {
			repository => {
				type => 'git',
				url  => 'https://github.com/scottchiefbaker/perl-ULID-Tiny.git',
				web  => 'https://github.com/scottchiefbaker/perl-ULID-Tiny',
			},
		},
	},
);

# vim: tabstop=4 shiftwidth=4 noexpandtab autoindent softtabstop=4
