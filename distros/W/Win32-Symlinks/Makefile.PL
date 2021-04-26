use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
my $file_spec = eval {
	require File::Spec;
};

my %WriteMakefileArgs = (
    NAME             => 'Win32::Symlinks',
    AUTHOR           => q{Francisco Zarabozo <zarabozo@cpan.org>},
    VERSION_FROM     => 'lib/Win32/Symlinks.pm',
    ABSTRACT_FROM    => 'lib/Win32/Symlinks.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
		'XSLoader'            => '0',
		'ExtUtils::MakeMaker' => '7.12',
    },
    TEST_REQUIRES => {
        'Test::More'     => '0',
		'File::Spec'     => '0',
		'File::Basename' => '0',
		'Cwd'            => '0',
    },
    PREREQ_PM => {
		'File::Spec'     => '0',
		'File::Basename' => '0',
		'Cwd'            => '0',
	},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Win32-Symlinks-*' },
	#CCFLAGS => '-Wall -std=c99',
	OPTIMIZE => '-O3',
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };
if ($^O eq 'MSWin32') {
	$WriteMakefileArgs{XSMULTI} = 1;
	for my $i (qw(CONFIGURE_REQUIRES TEST_REQUIRES PREREQ_PM)) {
		$WriteMakefileArgs{$i}->{'Win32::Shortcut'} = '0';
	}
}

WriteMakefile(%WriteMakefileArgs);

