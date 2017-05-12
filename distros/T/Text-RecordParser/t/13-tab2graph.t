#!perl

use strict;
use Config;
use File::Basename qw( basename );
use File::Spec::Functions;
use FindBin qw( $Bin );
use Readonly;
use Test::More;

Readonly my $TEST_COUNT    => 4;
Readonly my $PERL          => $^X;
Readonly my $TEST_DATA_DIR => catdir( $Bin, 'data' );
Readonly my $TAB2GRAPH     => catfile( $Bin, '..', 'bin', 'tab2graph' );

plan tests => $TEST_COUNT;

ok( -e $TAB2GRAPH, 'Script exists' );

SKIP: {
    eval { require GraphViz };

    if ($@) {
        skip 'GraphViz not installed', $TEST_COUNT - 1;
    }

    my $data = catfile( $TEST_DATA_DIR, 'tabular.tab' );
    ok( -e $data, 'Data file exists' );

    my $out_file = catfile( $Bin, 'foo.png' );
    my $command  = "$PERL $TAB2GRAPH -c -o $out_file $data 2>&1";
    my $out      = `$command`;
    my $basename = basename( $out_file );
    is( $out, qq[Image created "$basename."\n], 'Diagnostic OK' );
    my $file_size = -s $out_file;
    ok( $file_size > 0, 'File is correct size' );
    unlink $out_file;
};
