use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();

# Recurrence.xs sits at the top of the dist and the build is the plain
# single-extension one MakeMaker defaults to, for the reason HAMT's
# Makefile.PL gives: the import-library rule Strawberry adds for MinGW reads
# $(BASEEXT).def in the top directory.

sub inc_dirs { my @d; push @d, $1 while $_[0] =~ /-I(\S+)/g; return @d }

# ---- Time::Keeper::Recurrence as an ABI CONSUMER ------------------------- *
# A rule's occurrences are Time::Keeper values and its wall times are
# resolved by Time::Keeper::Zone, both reached through their C ABIs, so the
# headers are time_keeper_abi.h and time_keeper_zone_abi.h. A sibling
# checkout comes first, ahead of an installed copy, as everywhere in this
# workspace: an installed header older than the sibling's would otherwise
# win and compile against a table the sibling no longer has.
#
# Both are REQUIRED. There is nothing to degrade to, so a build that finds a
# header in neither place stops here.
my $pkg = eval { ExtUtils::Depends->new('Time::Keeper::Recurrence', 'Time::Keeper', 'Time::Keeper::Zone') };
my ($tk_inc, $tkz_inc);
{
    my $inst = '';
    if ($pkg) {
        my %v = $pkg->get_makefile_vars;
        $inst = $v{INC} || '';
    }
    for my $d (grep { -d } ('../Time-Keeper/include'), inc_dirs($inst)) {
        next unless -f "$d/time_keeper_abi.h";
        $tk_inc = $d;
        last;
    }
    for my $d (grep { -d } ('../Time-Keeper-Zone/include'), inc_dirs($inst)) {
        next unless -f "$d/time_keeper_zone_abi.h";
        $tkz_inc = $d;
        last;
    }
    die "Time::Keeper::Recurrence needs Time::Keeper 0.05 installed, or present as the "
      . "sibling ../Time-Keeper: its time_keeper_abi.h is what a rule's occurrences are made with.\n"
        unless $tk_inc;
    die "Time::Keeper::Recurrence needs Time::Keeper::Zone 0.04 installed, or present as the "
      . "sibling ../Time-Keeper-Zone: its time_keeper_zone_abi.h is what a rule's wall times are resolved with.\n"
        unless $tkz_inc;
    print "time_keeper_abi.h: from $tk_inc\ntime_keeper_zone_abi.h: from $tkz_inc\n";
}

$pkg ||= ExtUtils::Depends->new('Time::Keeper::Recurrence');

# Its own header, for C consumers (Punk::Queue's scheduler): ExtUtils::Depends
# installs it and records where it went, with the two it includes.
$pkg->install('include/time_keeper_recurrence_abi.h');
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');
my %dep = $pkg->get_makefile_vars;
# EU::Depends hands back an empty LIBS/LDFROM that would clobber MakeMaker's
# defaults, and an INC that names only installed copies. INC is set below
# from whichever headers were found.
delete @dep{qw(LIBS LDFROM INC)};

# Its PM map REPLACES MakeMaker's auto-detected one, so everything under lib/
# has to be re-added by hand or it silently stops being installed.
File::Find::find(sub {
    return unless -f && /\.pm\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

# MakeMaker maps Recurrence.xs -> Recurrence.c and rescans neither the
# INCLUDEd xs/ fragments nor the C headers, so name both. The globs run at
# CONFIGURE time - re-run Makefile.PL after adding a file.
my $xs_deps = join ' ', glob('xs/*.xs');
my $h_deps  = join ' ', glob('include/tkr/*.h'), 'include/time_keeper_recurrence_abi.h';

my %WriteMakefileArgs = (
    NAME             => 'Time::Keeper::Recurrence',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Time/Keeper/Recurrence.pm',
    ABSTRACT_FROM    => 'lib/Time/Keeper/Recurrence.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    # Both at configure time as well as at runtime: their headers are needed
    # to compile, and ExtUtils::Depends finds them through Install::Files.
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'Time::Keeper'        => '0.05',
        'Time::Keeper::Zone'  => '0.04',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => {
        'Time::Keeper'       => '0.05',
        'Time::Keeper::Zone' => '0.04',
    },
    XS     => { 'Recurrence.xs' => 'Recurrence.c' },
    OBJECT => 'Recurrence$(OBJ_EXT)',
    INC    => "-I. -Iinclude -I$tk_inc" . ($tkz_inc eq $tk_inc ? '' : " -I$tkz_inc"),
    depend => {
        'Recurrence.c'         => $xs_deps,
        'Recurrence$(OBJ_EXT)' => $h_deps,
    },
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Time-Keeper-Recurrence-* Install/Files.pm' },
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
