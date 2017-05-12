use Test::Filename tests => 1;

my @files = glob "examples/*";

filename_is( $files[0], 'examples/simple.t', "first file is simple.t" );

