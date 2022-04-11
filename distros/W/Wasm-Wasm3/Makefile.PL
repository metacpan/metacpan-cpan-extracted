use strict;
use warnings;

use ExtUtils::MakeMaker::CPANfile;
use ExtUtils::CBuilder;
use File::Temp;
use File::Spec;

#my @defines = _determine_defines($basic_inc, $libs);

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
    INC               => '-Wall -std=c99',
    LICENSE           => "perl_5",

    OBJECT => join(
        q< >,
        '$(BASEEXT)$(OBJ_EXT)',
        File::Spec->catfile( qw(wasm3 source libm3.a) ),
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

    # _GNU_SOURCE is for Cygwin. It still fails to build, but at least
    # it’s a bit closer to success this way.
    return <<"MAKE_FRAG"

.PHONY:
build-wasm3:
\t$cmake_path -D CMAKE_C_FLAGS='-fPIC -D_GNU_SOURCE' -S wasm3 -B wasm3
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
