use strict;
use warnings;

use Env qw/@PATH/;
use XS::Install;
use Alien::cmake3;

my $tag     = '20200114';
my $src_dir = "libdwarf";
my $bdir    = "$src_dir/build";

unshift @PATH, Alien::cmake3->bin_dir;
mkdir $bdir unless -d $bdir;
my $result = system("cd $bdir && cmake -G \"Unix Makefiles\" -DDWARF_WITH_LIBELF=off -DBUILD_NON_SHARED=on -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS=\"-O2 -fPIC\" ..");
die "FATAL: can't configure\n" if $result != 0;

my %params = (
    NAME   => 'XS::libdwarf',
    CLIB   => [{
        DIR       => "$bdir/libdwarf/",
        FILE      => 'libdwarf.a',
        BUILD_CMD => '$(MAKE)',
    }],
    LIBS      => '-lz',
    clean     => {FILES => $bdir},
    BIN_SHARE => {
        INCLUDE  => {
            "$src_dir/libdwarf/"       => '/libdwarf',
            "$src_dir/build/libdwarf/" => '/libdwarf',
        },
    },
    CONFIGURE_REQUIRES => {"Alien::cmake3" => '0.04'},
);

write_makefile(%params);
