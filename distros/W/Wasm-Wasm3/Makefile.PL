use strict;
use warnings;

use ExtUtils::MakeMaker::CPANfile;
use ExtUtils::CBuilder;
use File::Temp;
use File::Spec;

my $uvwasi_inc = File::Spec->catdir( qw( wasm3 _deps uvwasi-src include ) );

my %OS_CAN_UVWASI = map { $_ => 1 } (
    'linux',
    'darwin',
    'freebsd',
    'openbsd',
);

my $use_uvwasi = $OS_CAN_UVWASI{$^O} || 0;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Wasm::Wasm3',
    VERSION_FROM      => 'lib/Wasm/Wasm3.pm', # finds $VERSION
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Wasm/Wasm3.pm', # retrieve abstract from module
       AUTHOR         => [
            'Felipe Gasper (FELIPE)',
        ],
      ) : ()
    ),
    LICENSE => "perl_5",

    INC => join(
        q< >,
        ( $use_uvwasi ? "-I$uvwasi_inc" : () ),
        '-Wall',
        '-std=c99',
    ),

    DEFINE => join(
        q< >,
        "-DWW3_UVWASI=$use_uvwasi",
        ($use_uvwasi ? '-Dd_m3HasUVWASI' : ()),
    ),

    LIBS => ($use_uvwasi ? '-lpthread' : q<>),

    OBJECT => join(
        q< >,
        '$(BASEEXT)$(OBJ_EXT)',
        File::Spec->catfile( qw(wasm3 source libm3.a) ),
        (
            $use_uvwasi
            ? (
                File::Spec->catfile( qw(wasm3 _deps uvwasi-build libuvwasi_a.a) ),
                File::Spec->catfile( qw(wasm3 _deps libuv-build libuv_a.a) ),
            )
            : (),
        ),
    ),

    PMLIBDIRS => ['lib'],

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/FGasper/p5-Wasm-Wasm3.git',
                web => 'https://github.com/FGasper/p5-Wasm-Wasm3',
            },
            bugtracker => {
                web => 'https://github.com/FGasper/p5-Wasm-Wasm3/issues',
            },
        },
    },
);

# ----------------------------------------------------------------------

package MY;

use Alien::cmake3;
use Config;

sub postamble {
    my $cmake_path = File::Spec->catfile(
        Alien::cmake3->bin_dir(),
        Alien::cmake3->exe(),
    );

    my @cflags = (
        '-fPIC',
    );

    my @cmake_opts = (
        ( $use_uvwasi ? () : (-D => 'BUILD_WASI=simple' ) ),

        # _GNU_SOURCE is for Cygwin to have ptsname(), which doesn’t really
        # matter for now since Cygwin can’t do WASI, but we might as well:
        -D => qq/CMAKE_C_FLAGS='@cflags'/,

        -D => "APP_DIR='../wasm3-dummy-app-dir'",
    );

    if ($^O eq 'MSWin32') {
        push @cmake_opts, -G => q<'MinGW Makefiles'>,
    }

    return <<"MAKE_FRAG"

.PHONY:
build-wasm3:
\t$cmake_path @cmake_opts -S wasm3 -B wasm3
\t\$(MAKE) -C wasm3
MAKE_FRAG
}

my $orig_top_targets;
BEGIN {
$orig_top_targets = __PACKAGE__->can('top_targets');
}

sub top_targets {
    my $out = $orig_top_targets->(@_);

    $out =~ s<^(all\s*:+s*)><$1 build-wasm3 >;

    return $out;
}
