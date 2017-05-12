#!./perl

#	@(#)dbmoney.t	1.8	10/16/95

print "1..32\n";

require 'sybperl.pl';

use lib 't';
use _test;
use vars qw($Pwd $Uid $Srv $Db);

($Uid, $Pwd, $Srv, $Db) = _test::get_info();

$Sybase::DBlib::Version = $Sybase::DBlib::Version;

( ($dbproc = &dblogin($Uid, $Pwd, $Srv)) != -1 )
    and print("ok 1\n")		# 
    or die "not ok 1
-- You may need to edit t/dbmoney.t to add login names and passwords\n";

( &dbuse($dbproc, 'master') == $SUCCEED )
    and print("ok 2\n")
    or print "not ok 2\n";

$money1 = '4.89';
$money2 = '8.56';
$money3 = '*';

($status, $money3) = &dbmnyzero( );
($status == $SUCCEED && $money3 == 0)
    and print "ok 3\n"
    or print "not ok 3\n";

($status, $money3) = &dbmnyinc( $money3 );
($status, $money3) = &dbmnyinc( $money3 );
($status, $money3) = &dbmnyinc( $money3 );
($status, $money3) = &dbmnyinc( $money3 );
($status == $SUCCEED && $money3 == 0.0004)
    and print "ok 4\n"
    or print "not ok 4\n";

$money3 = '0.0001';
($status, $money3) = &dbmnyscale( $money3, 100, 1 );
($status == $SUCCEED && $money3 == 0.0101)
    and print "ok 5\n"
    or print "not ok 5\n";
    
( $money3, $money4 ) = ( '0.0001', '0.0002' );
($status, $money3) = &dbmnyadd( $money4, $money3 );
($status == $SUCCEED && $money3 == 0.0003)
    and print "ok 6\n"
    or print "not ok 6\n";

$money3 = '0.0004'; $money4 = '0.0003'; $money5 = '0.0005';
$money6 = '0.0004';

(&dbmnycmp($money3, $money4) == 1)
    and print "ok 7\n"
    or print "not ok 7\n";
(&dbmnycmp($money3, $money5) == -1)
    and print "ok 8\n"
    or print "not ok 8\n";
(&dbmnycmp($money3, $money6) == 0)
    and print "ok 9\n"
    or print "not ok 9\n";
(&dbmnycmp($money4, $money5) == -1)
    and print "ok 10\n"
    or print "not ok 10\n";
(&dbmnycmp($money4, $money6) == -1)
    and print "ok 11\n"
    or print "not ok 11\n";
(&dbmnycmp($money5, $money6) == 1)
    and print "ok 12\n"
    or print "not ok 12\n";

($status, $money3) = &dbmnyadd( $money1, $money2 );
($status == $SUCCEED && $money3 == 13.45)
    and print "ok 13\n"
    or print "not ok 13\n";

($status, $money3) = &dbmnysub( $money1, $money2 );
($status == $SUCCEED && $money3 == -3.67)
    and print "ok 14\n"
    or print "not ok 14\n";

($status, $money3) = &dbmnydivide( $money3, $money2 );
($status == $SUCCEED && $money3 == -0.4287)
    and print "ok 15\n"
    or print "not ok 15\n";

($status, $money4) = &dbmnymaxneg( );
($status == $SUCCEED && $money4 == -922337203685477.5808)
    and print "ok 16\n"
    or print "not ok 16\n";

($status, $money3) = &dbmnymaxpos( );
($status == $SUCCEED && $money3 == 922337203685477.5807)
    and print "ok 17\n"
    or print "not ok 17\n";

($status, $money4) = &dbmnyzero( );

@tbal = ( '4.89', '8.92', '7.77', '11.11', '0.01' );

for ( $cntr = 0 ; $cntr <= $#tbal ; $cntr++ ) {
  ($status, $money4) = &dbmnyadd( $tbal[ $cntr ], $money4 );
}
($status == $SUCCEED && $money4 == 32.70)
    and print "ok 18\n"
    or print "not ok 18\n";

$cntr = $#tbal + 1;

($status, $money4) = &dbmnydivide( $money4, $cntr );
($status == $SUCCEED && $money4 == 6.54)
    and print "ok 19\n"
    or print "not ok 19\n";

#print "-------------------------\n";

$money1 = '4.89';
$money2 = '8.56';
$money3 = '*';

($status, $money3) = &dbmny4zero( );
($status == $SUCCEED && $money3 == 0)
    and print "ok 20\n"
    or print "not ok 20\n";

( $money3, $money4 ) = ( '0.0001', '0.0002' );
($status, $money3) = &dbmny4add( $money3, $money4 );
($status == $SUCCEED && $money3 == 0.0003)
    and print "ok 21\n"
    or print "not ok 21\n";

$money3 = '0.0004'; $money4 = '0.0003'; $money5 = '0.0005';
$money6 = '0.0004';
(&dbmny4cmp($money3, $money4) == 1)
    and print "ok 22\n"
    or print "not ok 22\n";
(&dbmny4cmp($money3, $money5) == -1)
    and print "ok 23\n"
    or print "not ok 23\n";
(&dbmny4cmp($money3, $money6) == 0)
    and print "ok 24\n"
    or print "not ok 24\n";
(&dbmny4cmp($money4, $money5) == -1)
    and print "ok 25\n"
    or print "not ok 25\n";
(&dbmny4cmp($money4, $money6) == -1)
    and print "ok 26\n"
    or print "not ok 26\n";
(&dbmny4cmp($money5, $money6) == 1)
    and print "ok 27\n"
    or print "not ok 27\n";

($status, $money3) = &dbmny4add( $money1, $money2 );
($status == $SUCCEED && $money3 == 13.45)
    and print "ok 28\n"
    or print "not ok 28\n";

($status, $money3) = &dbmny4sub( $money1, $money2 );
($status == $SUCCEED && $money3 == -3.67)
    and print "ok 29\n"
    or print "not ok 29\n";

($status, $money3) = &dbmny4divide( $money3, $money2 );
($status == $SUCCEED && $money3 == -0.4287)
    and print "ok 30\n"
    or print "not ok 30\n";
($status, $money4) = &dbmny4zero( );

@tbal = ( '4.89', '8.92', '7.77', '11.11', '0.01' );

for ( $cntr = 0 ; $cntr <= $#tbal ; $cntr++ ) {
  ($status, $money4) = &dbmny4add( $tbal[ $cntr ], $money4 );
}

($status == $SUCCEED && $money4 == 32.70)
    and print "ok 31\n"
    or print "not ok 31\n";

$cntr = $#tbal + 1;

($status, $money4) = &dbmny4divide( $money4, $cntr );
($status == $SUCCEED && $money4 == 6.54)
    and print "ok 32\n"
    or print "not ok 32\n";

&dbclose($dbproc);

&dbexit;
