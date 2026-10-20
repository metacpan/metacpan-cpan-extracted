use 5.010;
use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();

my $pkg = eval { ExtUtils::Depends->new('Time::Keeper::Sky', 'Time::Keeper') };
unless ($pkg) {
    warn "Time::Keeper::Sky needs Time::Keeper to be installed before it is configured:\n$@";
    exit 0;
}

my %dep = $pkg->get_makefile_vars;
delete @dep{qw(LIBS LDFROM)};
my $tk_inc = delete $dep{INC} // '';

File::Find::find(sub {
    return unless -f && /\.pm\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

my $xs_deps = join ' ', glob('xs/*.xs');
my $h_deps  = join ' ', glob('include/tks/*.h');

sub flag_ok {
    my ($flag) = @_;
    my $ok = eval {
        require ExtUtils::CBuilder;
        my $cb = ExtUtils::CBuilder->new(quiet => 1);
        return 0 unless $cb->have_compiler;
        my $src = 'tks_probe_flag.c';
        open my $fh, '>', $src or return 0;
        print $fh "int tks_probe(double a, double b, double c) { return a * b + c > 0.0; }\n";
        close $fh;
        my $obj;
        my $built = eval { $obj = $cb->compile(source => $src, extra_compiler_flags => [$flag, '-Werror']); 1 };
        unlink grep { defined && -e } $src, $obj;
        $built ? 1 : 0;
    };
    return $ok ? 1 : 0;
}

my @flags;
for my $flag ('-ffp-contract=off', ($Config{archname} =~ /^i[3-6]86/ ? '-mfpmath=sse' : ())) {
    my $taken = flag_ok($flag);
    print "$flag: ", ($taken ? 'yes' : 'no'), "\n";
    push @flags, $flag if $taken;
}

my %WriteMakefileArgs = (
    NAME             => 'Time::Keeper::Sky',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Time/Keeper/Sky.pm',
    ABSTRACT_FROM    => 'lib/Time/Keeper/Sky.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'Time::Keeper'        => '0.04',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => {
        'Time::Keeper' => '0.04',
    },
    XS     => { 'Sky.xs' => 'Sky.c' },
    OBJECT => 'Sky$(OBJ_EXT)',
    INC    => "-I. -Iinclude $tk_inc",
    (@flags ? (CCFLAGS => join(' ', $Config{ccflags}, @flags)) : ()),
    depend => {
        'Sky.c'         => $xs_deps,
        'Sky$(OBJ_EXT)' => $h_deps,
    },
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Time-Keeper-Sky-*' },
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
