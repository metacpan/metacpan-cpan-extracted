# Test malformed BASIC with number in text different from floating point

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

my $test           = "malformed";
my $input_bas_file = "t/input/$test.bas";
my $exp_dump_file  = "t/expected/$test.txt";
my $exp_list_file  = "t/expected/$test.bas";

# make .p to print number
make_p( $input_bas_file, "$test.p" );

# replace characters of number while keeping the floating point form
my @bin = unpack( "C*", path("$test.p")->slurp_raw );
$bin[ 0x4082 - 0x4009 ] = 0x1C + 2;
path("$test.p")->spew_raw( pack( "C*", @bin ) );

# dump and compare
dump_p( "$test.p", "$test.txt" );
compare_text( $exp_dump_file, "$test.txt" );

# try to list
eval { list_p( "$test.p", "$test.bas" ); };
like $@, qr/wrong floating point representation/;

if ( Test::More->builder->is_passing ) {
    unlink "$test.p";
    unlink "$test.txt";
    unlink "$test.bas";
}

done_testing;
