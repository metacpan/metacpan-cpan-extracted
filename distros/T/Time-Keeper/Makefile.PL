use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();

# Keeper.xs sits at the top of the dist and the build is the plain
# single-extension one, for the reason HAMT's Makefile.PL gives: an XSMULTI
# build writes its export list where Strawberry's import-library rule does
# not look.

# ---- Time::Keeper as a CONSUMER of Time::Keeper::Zone's C ABI ----------- *
# Named zones are answered by Zone's table, reached through
# time_keeper_zone_abi.h with no Perl call. ExtUtils::Depends finds that
# header where Zone installed it; the table itself is fetched the first time
# a named zone is asked for, not when Time::Keeper loads. Nothing is linked
# against Zone.
#
# Zone must be installed, or in @INC, before this file can run: that is what
# CONFIGURE_REQUIRES says below, and a missing one stops here by name.
my $pkg = eval { ExtUtils::Depends->new('Time::Keeper', 'Time::Keeper::Zone') };
unless ($pkg) {
    warn "Time::Keeper needs Time::Keeper::Zone to be installed before it is configured:\n$@";
    exit 0;
}

# ---- Time::Keeper as an ABI PROVIDER ------------------------------------ *
# time_keeper_abi.h publishes dates, zones, formatting and parsing to other
# extensions' C, resolved at run time through Time::Keeper::_abi_ptr.
# ExtUtils::Depends installs the header and records where it went. No
# set_inc: a provider's build-tree paths mean nothing to a consumer once
# installed.
$pkg->install('include/time_keeper_abi.h');
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');

my %dep = $pkg->get_makefile_vars;
# EU::Depends hands back an empty LIBS/LDFROM that would clobber MakeMaker's
# defaults. Its INC is the one thing wanted: where Zone's header is.
delete @dep{qw(LIBS LDFROM)};
my $zone_inc = delete $dep{INC} // '';

# Its PM map REPLACES MakeMaker's auto-detected one.
File::Find::find(sub {
    return unless -f && /\.pm\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');
$dep{PM}{'share/locales.tkd'} = '$(INST_LIB)/Time/Keeper/locales.tkd';

# Neither the INCLUDEd xs/ fragments nor the headers are rescanned by
# MakeMaker. The globs run at CONFIGURE time.
my $xs_deps = join ' ', glob('xs/*.xs');
my $h_deps  = join ' ', 'include/time_keeper_abi.h', glob('include/tk/*.h');

# clock_gettime gives the current time to the nanosecond. Config does not
# record whether it is there, and on glibc before 2.17 it links only with
# -lrt, so try it: a program that calls it must compile AND link with no
# extra library. Otherwise the C falls back to gettimeofday's microseconds.
sub have_clock_gettime {
    return 0 if $^O eq 'MSWin32';
    my $ok = eval {
        require ExtUtils::CBuilder;
        my $cb = ExtUtils::CBuilder->new(quiet => 1);
        return 0 unless $cb->have_compiler;
        my $src = 'tk_probe_clock.c';
        open my $fh, '>', $src or return 0;
        print $fh "#include <time.h>\nint main(void) { struct timespec ts; return clock_gettime(CLOCK_REALTIME, &ts); }\n";
        close $fh;
        my ($obj, $exe);
        my $built = eval {
            $obj = $cb->compile(source => $src);
            $exe = $cb->link_executable(objects => $obj);
            1;
        };
        unlink grep { defined && -e } $src, $obj, $exe;
        $built ? 1 : 0;
    };
    return $ok ? 1 : 0;
}

my $define = have_clock_gettime() ? '-DTK_HAVE_CLOCK_GETTIME' : '';
print "clock_gettime: ", ($define ? "yes" : "no, gettimeofday instead"), "\n";

my %WriteMakefileArgs = (
    NAME             => 'Time::Keeper',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Time/Keeper.pm',
    ABSTRACT_FROM    => 'lib/Time/Keeper.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'Time::Keeper::Zone'  => '0.03',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => {
        'Time::Keeper::Zone' => '0.03',
    },
    XS     => { 'Keeper.xs' => 'Keeper.c' },
    OBJECT => 'Keeper$(OBJ_EXT)',
    INC    => "-I. -Iinclude $zone_inc",
    DEFINE => $define,
    depend => {
        'Keeper.c'         => $xs_deps,
        'Keeper$(OBJ_EXT)' => $h_deps,
    },
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Time-Keeper-* Install/Files.pm' },
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
