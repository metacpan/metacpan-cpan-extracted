use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Find ();

# Business.xs sits at the top of the dist and the build is the plain
# single-extension one, for the reason HAMT's Makefile.PL gives: an XSMULTI
# build writes its export list where Strawberry's import-library rule does
# not look.

# ---- Time::Keeper::Business as a CONSUMER of Time::Keeper's C ABI ------- *
# Every date this dist reads or writes goes through time_keeper_abi.h with
# no Perl call. ExtUtils::Depends finds that header where Time::Keeper
# installed it; the table itself is fetched the first time it is needed,
# not when this module loads. Nothing is linked against Time::Keeper.
#
# TK_DIST names a Time-Keeper tree built beside this one, so a scratch build
# needs no installed core: its blib goes first on @INC, here and (through
# PERL5LIB) in the tests.
if (my $tk = $ENV{TK_DIST}) {
    unshift @INC, "$tk/blib/lib", "$tk/blib/arch";
    print "Time::Keeper taken from $tk/blib\n";
}

require ExtUtils::Depends;
my $pkg = eval { ExtUtils::Depends->new('Time::Keeper::Business', 'Time::Keeper') };
unless ($pkg) {
    warn "Time::Keeper::Business needs Time::Keeper 0.05 or later to be installed before it is configured:\n$@";
    exit 0;
}

my %dep = $pkg->get_makefile_vars;
# EU::Depends hands back an empty LIBS/LDFROM that would clobber MakeMaker's
# defaults. Its INC is the one thing wanted: where the core's header is.
delete @dep{qw(LIBS LDFROM)};
my $tk_inc = delete $dep{INC} // '';

# Its PM map REPLACES MakeMaker's auto-detected one.
File::Find::find(sub {
    return unless -f && /\.pm\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

# Neither the INCLUDEd xs/ fragments nor the headers are rescanned by
# MakeMaker. The globs run at CONFIGURE time.
my $xs_deps = join ' ', glob('xs/*.xs');
my $h_deps  = join ' ', glob('include/tkb/*.h');

my %WriteMakefileArgs = (
    NAME             => 'Time::Keeper::Business',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Time/Keeper/Business.pm',
    ABSTRACT_FROM    => 'lib/Time/Keeper/Business.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'Time::Keeper'        => '0.05',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => {
        'Time::Keeper' => '0.05',
    },
    XS     => { 'Business.xs' => 'Business.c' },
    OBJECT => 'Business$(OBJ_EXT)',
    INC    => "-I. -Iinclude $tk_inc",
    depend => {
        'Business.c'         => $xs_deps,
        'Business$(OBJ_EXT)' => $h_deps,
    },
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
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
