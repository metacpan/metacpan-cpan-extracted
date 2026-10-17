use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();

# Zone.xs sits at the top of the dist and the build is the plain
# single-extension one, for the reason HAMT's Makefile.PL gives: an XSMULTI
# build writes its export list where Strawberry's import-library rule does
# not look.

# ---- Time::Keeper::Zone as an ABI PROVIDER ------------------------------ *
# time_keeper_zone_abi.h publishes the zone engine to Time::Keeper's C,
# resolved at run time through Time::Keeper::Zone::_abi_ptr. ExtUtils::Depends
# installs the header and records where it went. NO set_inc, for the reason
# HAMT's Makefile.PL gives.
my $pkg = ExtUtils::Depends->new('Time::Keeper::Zone');
$pkg->install('include/time_keeper_zone_abi.h');
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');

my %dep = $pkg->get_makefile_vars;
delete @dep{qw(LIBS LDFROM INC)};

# Its PM map REPLACES MakeMaker's auto-detected one.
File::Find::find(sub {
    return unless -f && /\.pm\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

# Neither the INCLUDEd xs/ fragments nor the headers are rescanned by
# MakeMaker. The globs run at CONFIGURE time.
my $xs_deps = join ' ', glob('xs/*.xs');
my $h_deps  = join ' ', 'include/time_keeper_zone_abi.h', glob('include/tkz/*.h');

my %WriteMakefileArgs = (
    NAME             => 'Time::Keeper::Zone',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Time/Keeper/Zone.pm',
    ABSTRACT_FROM    => 'lib/Time/Keeper/Zone.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => {},
    XS     => { 'Zone.xs' => 'Zone.c' },
    OBJECT => 'Zone$(OBJ_EXT)',
    INC    => '-I. -Iinclude',
    depend => {
        'Zone.c'         => $xs_deps,
        'Zone$(OBJ_EXT)' => $h_deps,
    },
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Time-Keeper-Zone-* Install/Files.pm' },
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
