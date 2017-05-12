use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
my @poddirs = qw( blib script );
# Skip CodeGen.pm because the wonky mix of TT and POD confuses
# these tests.
my @podfiles = grep { $_ !~ /CodeGen/ } all_pod_files( @poddirs );
all_pod_files_ok( @podfiles );
