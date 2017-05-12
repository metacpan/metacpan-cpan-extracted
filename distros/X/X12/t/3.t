# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'
#########################
use strict;
use Test;
BEGIN { plan tests => 16 }
#########################
use FindBin;
use X12::Parser;

#setup
my ( $loop, $pos, $level );
my $sample_file = "$FindBin::RealBin/sample_835.txt";
my $sample_cf   = "$FindBin::RealBin/../cf/835_004010X091.cf";

#create a parser instance
my $p = new X12::Parser;
$p->parsefile( file => $sample_file, conf => $sample_cf );

#test 1
$loop = $p->get_next_loop;
ok( $loop, 'ISA' );

#test 2
$loop = $p->get_next_loop;
ok( $loop, 'GS' );

#test 3
( $pos, $loop ) = $p->get_next_pos_loop;
ok( $pos, 3 );

#test 4
( $pos, $level, $loop ) = $p->get_next_pos_level_loop;
ok( $level, 1 );

#test 5
#close the file
$p->closefile();

# parse the file again
$p->parsefile( file => $sample_file, conf => $sample_cf );
$loop = $p->get_next_loop;
ok( $loop, 'ISA' );

#test 6
$loop = $p->get_next_loop;
ok( $loop, 'GS' );

#test 7
( $pos, $loop ) = $p->get_next_pos_loop;
ok( $pos, 3 );

#test 8
( $pos, $level, $loop ) = $p->get_next_pos_level_loop;
ok( $level, 1 );

#test 9
#close the file
$p->closefile();

# parse the file again
open( my $handle, $sample_file );
$p->parse( handle => $handle, conf => $sample_cf );
$loop = $p->get_next_loop;
ok( $loop, 'ISA' );

#test 10
$loop = $p->get_next_loop;
ok( $loop, 'GS' );

#test 11
( $pos, $loop ) = $p->get_next_pos_loop;
ok( $pos, 3 );

#test 12
( $pos, $level, $loop ) = $p->get_next_pos_level_loop;
ok( $level, 1 );
close($handle);

#test 13
open( $handle, $sample_file );
$p->parse( handle => $handle, conf => $sample_cf );
$loop = $p->get_next_loop;
ok( $loop, 'ISA' );

#test 14
$loop = $p->get_next_loop;
ok( $loop, 'GS' );

#test 15
( $pos, $loop ) = $p->get_next_pos_loop;
ok( $pos, 3 );

#test 16
( $pos, $level, $loop ) = $p->get_next_pos_level_loop;
ok( $level, 1 );
close($handle);
