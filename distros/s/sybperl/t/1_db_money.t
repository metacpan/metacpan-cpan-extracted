#!./perl
# $Id: 1_db_money.t,v 1.2 2004/04/13 20:03:05 mpeppler Exp $
#
# from
#	@(#)money.t	1.2	3/4/96

print "1..13\n";

use Sybase::DBlib qw(2.04);

use lib 't';
use _test;

if(&Sybase::DBlib::DBLIBVS < 461) {
    print STDERR "Money routines are not implemented in this version.\n";
    for (1 .. 13) {
	print "ok $_\n";
    }
    exit(0);
}

use vars qw($Pwd $Uid $Srv $Db);

($Uid, $Pwd, $Srv, $Db) = _test::get_info();

$Sybase::DBlib::Version = $Sybase::DBlib::Version;
$Sybase::DBlib::Att{UseDateTime} = TRUE;

($dbh = new Sybase::DBlib $Uid, $Pwd, $Srv)
    and print("ok 1\n")		# 
    or die "not ok 1
-- The userid/password combination may be invalid - check the PWD file\n";

$dbh->{UseMoney} = TRUE;

$money1 = $dbh->newmoney('4.89');
$money2 = $dbh->newmoney('8.56');

$money3 = $dbh->newmoney('0.0001');
$money4 = $dbh->newmoney('0.0002');
$money3 += $money4;
($money3 == 0.0003)
    and print "ok 2\n"
    or print "not ok 2\n";

$money3 = $dbh->newmoney(0.0004);
$money4 = $dbh->newmoney(0.0003);
$money5 = $dbh->newmoney(0.0005);
$money6 = $dbh->newmoney(0.0004);

($money3 > $money4)
    and print "ok 3\n"
    or print "not ok 3\n";
($money3 < $money5)
    and print "ok 4\n"
    or print "not ok 4\n";
($money3 == $money6)
    and print "ok 5\n"
    or print "not ok 5\n";
($money4 < $money5)
    and print "ok 6\n"
    or print "not ok 6\n";
($money4 < $money6)
    and print "ok 7\n"
    or print "not ok 7\n";
($money5 > $money6)
    and print "ok 8\n"
    or print "not ok 8\n";

$money3 = $money1 + $money2;
($money3 == 13.45)
    and print "ok 9\n"
    or print "not ok 9\n";

$money3 = $money1 - $money2;
($money3 == -3.67)
    and print "ok 10\n"
    or print "not ok 10\n";

$money3 /= $money2;
($money3 == -0.4287)
    and print "ok 11\n"
    or print "not ok 11\n";


@tbal = ( '4.89', '8.92', '7.77', '11.11', '0.01' );
$money4->set(0);
for ( $cntr = 0 ; $cntr <= $#tbal ; $cntr++ ) {
    $money4 += $tbal[ $cntr ];
}
($money4 == 32.70)
    and print "ok 12\n"
    or print "not ok 12\n";

$cntr = $#tbal + 1;

$money4 /= $cntr;
($money4 == 6.54)
    and print "ok 13\n"
    or print "not ok 13\n";

