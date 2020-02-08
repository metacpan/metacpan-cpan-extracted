use strict;
use warnings;
use XS::Install;
use Alien::cmake3;
use Env qw/@PATH/;

my $version = '3.7.3';
my $src_dir = "geos-${version}";
my $bdir    = "$src_dir/build";

unshift @PATH, Alien::cmake3->bin_dir;

my $cmake_flags = join(" ", '-G "Unix Makefiles"', '-DCMAKE_CXX_FLAGS="-O2 -fPIC"', '-DCMAKE_C_FLAGS="-O2 -fPIC"',
    qw/
    -DGEOS_ENABLE_TESTS=off
    -DGEOS_ENABLE_INLINE=off
    -DGEOS_BUILD_STATIC=on
    -DGEOS_BUILD_SHARED=off
    -DGEOS_BUILD_CAPI=off
    -DCMAKE_BUILD_TYPE=Release
    /
);
mkdir $bdir unless -d $bdir;
my $result = system("cd $bdir && cmake $cmake_flags ..");
die "FATAL: can't configure geos cmake\n" if $result != 0;

my %params = (
    NAME               => 'XS::libgeos',
    CPLUS              => 11,
    CONFIGURE_REQUIRES => {"Alien::cmake3" => '0.04'},
    clean              => {FILES => $bdir},
    CLIB => {
        DIR       => $bdir,
        FILE      => 'lib/libgeos.a',
        BUILD_CMD => '$(MAKE)',
    },
    BIN_SHARE => {
        INCLUDE  => {
            "$src_dir/build/include" => '/',
            "$src_dir/include"       => '/',
        },
    },
);

write_makefile(%params);
