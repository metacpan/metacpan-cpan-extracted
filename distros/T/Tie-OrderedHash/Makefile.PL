use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use Config;


my %platform_args;
if ($^O eq 'linux' || $^O eq 'freebsd' || $^O eq 'netbsd'
        || $^O eq 'dragonfly') {
    $platform_args{LDDLFLAGS} = $Config{lddlflags}
        . ' -Wl,--export-dynamic -Wl,-soname,OrderedHash.so';
}
elsif ($^O eq 'MSWin32' || $^O eq 'cygwin' || $^O eq 'msys') {
    my $implib = 'blib/arch/auto/Tie/OrderedHash/libOrderedHash.dll.a';
    $platform_args{LDDLFLAGS} = ($Config{lddlflags} || '')
        . ' -Wl,--export-all-symbols'
        . " -Wl,--out-implib=$implib";
}
# macOS / others: bundle linker uses dynamic_lookup, no special handling.

my $pkg = ExtUtils::Depends->new('Tie::OrderedHash');
$pkg->set_inc('-I. -Iinclude');
$pkg->install('include/tie_orderedhash.h');

if ($^O eq 'MSWin32' || $^O eq 'cygwin' || $^O eq 'msys') {
    my $arch = $Config{installsitearch};
    $pkg->set_libs(qq{-L"$arch/auto/Tie/OrderedHash" -lOrderedHash});
}

mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');
my %dep_vars = $pkg->get_makefile_vars;

# ExtUtils::Depends doesn't auto-include the .pm; wire it in.
$dep_vars{PM}{'lib/Tie/OrderedHash.pm'} = '$(INST_LIB)/Tie/OrderedHash.pm';

my %WriteMakefileArgs = (
    NAME             => 'Tie::OrderedHash',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Tie/OrderedHash.pm',
    ABSTRACT_FROM    => 'lib/Tie/OrderedHash.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010000',
    macro            => { TARFLAGS   => "--format=ustar -c -v -f" },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {},
    OBJECT => 'OrderedHash$(OBJ_EXT) oh_core$(OBJ_EXT)',
    C      => ['oh_core.c'],
    XS     => { 'OrderedHash.xs' => 'OrderedHash.c' },
    dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean  => { FILES => 'Tie-OrderedHash-* OrderedHash.c OrderedHash.o '
                       . 'oh_core.o Install/Files.pm' },
    %platform_args,
    # ExtUtils::Depends provides INC + the PM rules to install
    # tie_orderedhash.h + Install/Files.pm under .../Tie/OrderedHash/.
    # Our own lib/Tie/OrderedHash.pm is wired in above.
    %dep_vars,
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
