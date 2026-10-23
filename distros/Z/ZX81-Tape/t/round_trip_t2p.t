# Test round-trip to files generated with t2p

#use warnings FATAL => 'all';
#use Carp qw(confess);
#$SIG{__WARN__} = sub { confess @_ };

use Modern::Perl;
use Path::Tiny;
use Test::HexDifferences;
use Test::More;
use Text::Diff;

BEGIN { use lib 't'; require 'testlib.pl'; }
BEGIN { use_ok 'ZX81::Tape', 'make_p', 'dump_p', 'list_p' }

for my $input_bas_file ( path("t/t2p/input")->children(qr/\.bas$/) ) {
    note "input file: $input_bas_file";
    my $input_basename = $input_bas_file->basename(".bas");
    my $exp_p_file     = path("t/t2p/expected")->child("$input_basename.p");
    my $exp_dump_file  = path("t/t2p/expected")->child("$input_basename.txt");
    my $exp_list_file  = path("t/t2p/expected")->child("$input_basename.bas");

    # make .p file from .bas and compare to expected
    make_p( $input_bas_file, "$input_basename.p" );
    compare_p( $exp_p_file, "$input_basename.p" );

    if ( Test::More->builder->is_passing ) {
        unlink "$input_basename.p";
    }

    # repeat using the stript
    system $^X, "-Iblib/lib", "./bin/zx81_make_p", "-o", "$input_basename.p",
      "$input_bas_file";
    compare_p( $exp_p_file, "$input_basename.p" );

    if ( Test::More->builder->is_passing ) {
        unlink "$input_basename.p";
    }

    # make dump file from .p and compare to expected
    dump_p( $exp_p_file, "$input_basename.txt" );
    compare_text( $exp_dump_file, "$input_basename.txt" );

    if ( Test::More->builder->is_passing ) {
        unlink "$input_basename.txt";
    }

    # repeat using the stript
    system $^X, "-Iblib/lib", "./bin/zx81_dump_p", "-o", "$input_basename.txt",
      "$exp_p_file";
    compare_text( $exp_dump_file, "$input_basename.txt" );

    if ( Test::More->builder->is_passing ) {
        unlink "$input_basename.txt";
    }

    # make list file from .p and compare to expected
    list_p( $exp_p_file, "$input_basename.bas" );
    compare_text( $exp_list_file, "$input_basename.bas" );

    if ( Test::More->builder->is_passing ) {
        unlink "$input_basename.bas";
    }

    # repeat using the stript
    system $^X, "-Iblib/lib", "./bin/zx81_list_p", "-o", "$input_basename.bas",
      "$exp_p_file";
    compare_text( $exp_list_file, "$input_basename.bas" );

    if ( Test::More->builder->is_passing ) {
        unlink "$input_basename.bas";
    }

    # round-trip
    list_p( $exp_p_file, "$input_basename.2.bas" );
    make_p( "$input_basename.2.bas", "$input_basename.2.p" );
    compare_p( $exp_p_file, "$input_basename.2.p" );

    if ( Test::More->builder->is_passing ) {
        unlink "$input_basename.2.bas", "$input_basename.2.p";
    }
}

done_testing;
