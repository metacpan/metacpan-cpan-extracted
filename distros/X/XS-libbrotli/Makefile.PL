use strict;
use warnings;
use Alien::cmake3;
use Env qw/@PATH/;
use XS::Install;

my $libdir = "brotli";
my $bdir   = "$libdir/_build";

unshift @PATH, Alien::cmake3->bin_dir;
mkdir $bdir unless -d $bdir;
my $result = system(qq{cd $bdir && cmake .. -G "Unix Makefiles" -DCMAKE_C_FLAGS="-O2 -fPIC" -DCMAKE_BUILD_TYPE=Release -DBROTLI_DISABLE_TESTS=yes -DBUILD_SHARED_LIBS=no});
die "can't configure cmake\n" if $result != 0;

my %params = (
    NAME   => 'XS::libbrotli',
    CLIB   => [
        {DIR => $bdir, FILE => 'libbrotlicommon.a', BUILD_CMD => '$(NOOP)', BUILD_DEP=>'brotli-all'},
        {DIR => $bdir, FILE => 'libbrotlidec.a',    BUILD_CMD => '$(NOOP)', BUILD_DEP=>'brotli-all'},
        {DIR => $bdir, FILE => 'libbrotlienc.a',    BUILD_CMD => '$(NOOP)', BUILD_DEP=>'brotli-all'},
    ],        
    BIN_SHARE => {
        INCLUDE  => {
            "$libdir/c/include/" => '/',
        },
    },
    CONFIGURE_REQUIRES => {"Alien::cmake3" => '0.04'},
    clean              => {FILES => $bdir},
    postamble          => "brotli-all: ; cd $bdir && \$(MAKE)",
);

write_makefile(%params);
