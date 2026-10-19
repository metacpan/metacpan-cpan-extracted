# Test round-trip for features not available in t2p

use Modern::Perl;
use Path::Tiny;
use Test::HexDifferences;
use Test::More;
use Text::Diff;
use File::Copy;

BEGIN { use lib 't'; require 'testlib.pl'; }
BEGIN { use_ok 'ZX81::Tape', 'make_p', 'dump_p', 'list_p' }

for my $input_bas_file ( path("t/specific/input")->children(qr/\.bas$/) ) {
    note "input file: $input_bas_file";
    my $input_basename = $input_bas_file->basename(".bas");
    my $exp_p_file = path("t/specific/expected")->child("$input_basename.p");
    my $exp_dump_file =
      path("t/specific/expected")->child("$input_basename.txt");
    my $exp_list_file =
      path("t/specific/expected")->child("$input_basename.bas");

    # make .p
    make_p( $input_bas_file, "$input_basename.p" );

    # make dump file from .p and compare to expected
    dump_p( "$input_basename.p", "$input_basename.txt" );
    compare_text( $exp_dump_file, "$input_basename.txt" );

    # make list file from .p and compare to expected
    list_p( "$input_basename.p", "$input_basename.bas" );
    compare_text( $exp_list_file, "$input_basename.bas" );

    # round-trip
    make_p( "$input_basename.bas", "$input_basename.2.p" );
    compare_p( "$input_basename.p", "$input_basename.2.p" );

    # save generated .p
    copy( "$input_basename.p", $exp_p_file );

    if ( Test::More->builder->is_passing ) {
        unlink "$input_basename.p";
        unlink "$input_basename.txt";
        unlink "$input_basename.bas";
        unlink "$input_basename.2.p";
    }
}

done_testing;
