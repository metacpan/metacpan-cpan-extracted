use strict;
use XS::Install;
use Alien::cmake3;
use Env qw/@PATH/;

my $bdir = "libcares/build";

unshift @PATH, Alien::cmake3->bin_dir;
mkdir($bdir) unless -d $bdir;
my $flags = qq{-DCARES_STATIC=ON -DCARES_STATIC_PIC=ON -DCARES_SHARED=OFF -DCMAKE_C_FLAGS="-O2"};
my $result = system(qq{cd $bdir && cmake .. -G "Unix Makefiles" $flags});
die "FATAL: could not make libcares' Makefile\n" if $result != 0;

my $libs = '';
$libs .= ' -lrt' if $^O eq 'linux'; # for older linux

my %params = (
    NAME               => 'XS::libcares',
    CONFIGURE_REQUIRES => {'Alien::cmake3' => 0},
    clean              => {FILES => $bdir},
    LIBS               => $libs,
    BIN_SHARE => {
        INCLUDE => {
            (map {; "libcares/$_" => "/$_" } qw# ares.h ares_version.h ares_dns.h ares_rules.h #),
            "$bdir/ares_build.h" => "/ares_build.h",
        },
    },
    CLIB => {
        DIR       => $bdir,
        FILE      => 'lib/libcares.a',
        BUILD_CMD => '$(MAKE)',
    },
);

write_makefile(%params);
