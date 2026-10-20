use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();

# Natural.xs sits at the top of the dist and the build is the plain
# single-extension one, as Time-Keeper's is.

# ---- a CONSUMER of Time::Keeper's C ABI -------------------------------- *
# Every Time::Keeper call Natural makes while reading a text goes through
# time_keeper_abi.h's table (version 3, Time::Keeper 0.07), found at BOOT
# through Time::Keeper::_abi_ptr. ExtUtils::Depends finds the header where
# Time::Keeper installed it; nothing is linked against Time::Keeper.
my $pkg = eval { ExtUtils::Depends->new('Time::Keeper::Natural', 'Time::Keeper') };
unless ($pkg) {
    warn "Time::Keeper::Natural needs Time::Keeper 0.08 to be installed before it is configured:\n$@";
    exit 0;
}
my %dep = $pkg->get_makefile_vars;
delete @dep{qw(LIBS LDFROM PM)};
my $tk_inc = delete $dep{INC} // '';

# The PM map is written here so that the word tables and number words a
# later phase puts in share/ install beside the module, with no File::ShareDir.
my %pm;
File::Find::find(sub {
    return unless -f && /\.pm\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $pm{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');
for my $f (glob('share/words/*.txt'), glob('share/numbers/*.txt')) {
    (my $rel = $f) =~ s{^share/}{};
    $pm{$f} = "\$(INST_LIB)/Time/Keeper/Natural/$rel";
}

my $xs_deps = join ' ', glob('xs/*.xs');
my $h_deps  = join ' ', glob('include/tkn/*.h');

my %WriteMakefileArgs = (
    NAME             => 'Time::Keeper::Natural',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Time/Keeper/Natural.pm',
    ABSTRACT_FROM    => 'lib/Time/Keeper/Natural.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'Time::Keeper'        => '0.08',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => {
        'Time::Keeper' => '0.08',
    },
    PM     => \%pm,
    XS     => { 'Natural.xs' => 'Natural.c' },
    OBJECT => 'Natural$(OBJ_EXT)',
    INC    => "-I. -Iinclude $tk_inc",
    depend => {
        'Natural.c'         => $xs_deps,
        'Natural$(OBJ_EXT)' => $h_deps,
    },
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Time-Keeper-Natural-*' },
    %dep,
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

WriteMakefile(%WriteMakefileArgs);
