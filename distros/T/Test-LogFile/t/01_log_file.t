use strict;
use warnings;
use Test::More;
use Test::LogFile;

subtest 'only filename' => sub {
    my $file = log_file;
    ok( -e $file, "create temp log file" );
};

subtest 'fh and filename' => sub {
    my ( $fh, $file ) = log_file;
    ok( $fh, "get fh" );
    is( ref $fh, 'GLOB', "fh is valid" );
    ok( -e $file, "get log file by array" );
};

done_testing;
