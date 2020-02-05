use strict;
use warnings;
use Alien::cmake3;
use Env qw/@PATH/;
use XS::Install;

my $libdir = "brotli";
my $bdir   = "$libdir/build";

unshift @PATH, Alien::cmake3->bin_dir;
mkdir $bdir unless -d $bdir;
my $result = system(qq{cd $bdir && cmake .. -G "Unix Makefiles" -DCMAKE_C_FLAGS="-O2 -fPIC" -DCMAKE_BUILD_TYPE=Release});
die "can't configure cmake\n" if $result != 0;

my %params = (
    NAME   => 'XS::libbrotli',
    LDFROM => '-Wl,--whole-archive $(OBJECT) -Wl,--no-whole-archive',
    CLIB   => {
        DIR       => $bdir,
        FILE      => 'libbrotli-static.a',
        BUILD_CMD => '$(MAKE) brotli-static',
    },
    BIN_SHARE => {
        INCLUDE  => {
            "$libdir/c/include/" => '/',
        },
    },
    CONFIGURE_REQUIRES => {"Alien::cmake3" => '0.04'},
    clean              => {FILES => $bdir},
);

write_makefile(%params);
