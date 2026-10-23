# Test round-trip for features not available in t2p

#use warnings FATAL => 'all';
#use Carp qw(confess);
#$SIG{__WARN__} = sub { confess @_ };

use Modern::Perl;
use Path::Tiny;
use Test::HexDifferences;
use Test::More;
use Text::Diff;
use File::Copy;

BEGIN { use lib 't'; require 'testlib.pl'; }
BEGIN { use_ok 'ZX81::Tape', 'make_p', 'dump_p', 'list_p' }

for my $input_p_file ( path("t/p/input")->children(qr/\.p$/) ) {
    note "input file: $input_p_file";
    my $input_basename = $input_p_file->basename(".p");
    my $exp_dump_file  = path("t/p/expected")->child("$input_basename.txt");
    my $exp_list_file  = path("t/p/expected")->child("$input_basename.bas");

    # make dump file from .p and compare to expected
    dump_p( $input_p_file, "$input_basename.txt" );
    compare_text( $exp_dump_file, "$input_basename.txt" );

    # make list file from .p and compare to expected
    list_p( $input_p_file, "$input_basename.bas" );
    compare_text( $exp_list_file, "$input_basename.bas" );

    # round-trip
    make_p( "$input_basename.bas", "$input_basename.2.p" );
    compare_p( $input_p_file, "$input_basename.2.p" );

    if ( Test::More->builder->is_passing ) {
        unlink "$input_p_file.txt";
        unlink "$input_basename.p";
        unlink "$input_basename.p.txt";
        unlink "$input_basename.txt";
        unlink "$input_basename.bas";
        unlink "$input_basename.2.p";
        unlink "$input_basename.2.p.txt";
    }
}

done_testing;
