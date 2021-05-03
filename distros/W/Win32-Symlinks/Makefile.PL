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
    MIN_PERL_VERSION => '5.016',
    CONFIGURE_REQUIRES => {
        'XSLoader'            => '0',
        'ExtUtils::MakeMaker' => '7.12',
    },
    TEST_REQUIRES => {
        'Parse::Lnk'     => '0.06',
        'Test::More'     => '0',
        'File::Spec'     => '0',
        'File::Basename' => '0',
        'Cwd'            => '0',
    },
    PREREQ_PM => {
        'Parse::Lnk'     => '0.04',
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
}

if ($^O eq 'MSWin32' and $] < 5.016) {
    print STDERR "\n******* WARNING *******\n\n";
    print STDERR "This module requires Perl version 5.016 or higher. You are running $].\n";
    print STDERR "Perl versions prior to 5.016 don't support overriding the -l operator.\n\n";
    print STDERR "************************\n\n";
    delete $WriteMakefileArgs{XSMULTI};
}

if ($^O eq 'MSWin32' and not _mklink_works()) {
    print STDERR "\n******* WARNING *******\n\n";
    print STDERR "mklink doesn't seem to be available on this system.\n";
    print STDERR "The function symlink will not be overrided without it.\n\n";
    print STDERR "************************\n\n";
}


WriteMakefile(%WriteMakefileArgs);

sub _mklink_works {
	my $cmd = $ENV{COMSPEC} || 'cmd.exe';
	my $r = qx["$cmd" /c mklink /? 2>&1];
	if ($r =~ m[/D]i and $r =~ m[/H]i and $r =~ m[/J]i) {
		return 1;
	}
	return 0;
}

