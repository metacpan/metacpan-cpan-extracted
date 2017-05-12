# -*-Perl-*-
# $Id: 2_ct_xblk.t,v 1.5 2004/08/03 14:14:00 mpeppler Exp $
#
# From
# @(#)ctlib.t	1.17	03/05/98
#
# Small test script for Sybase::CTlib

BEGIN {print "1..21\n";}
END {print "not ok 1\n" unless $loaded;}
use Sybase::CTlib qw(2.01);
$loaded = 1;
print "ok 1\n";

$Version = $Sybase::CTlib::Version;

print "Sybperl Version $Version\n";

use lib 't';
use _test;
use vars qw($Pwd $Uid $Srv $Db);

($Uid, $Pwd, $Srv, $Db) = _test::get_info();

#ct_callback(CS_SERVERMSG_CB, \&srv_cb);
ct_callback(CS_CLIENTMSG_CB, \&clt_cb);
ct_callback(CS_MESSAGE_CB, \&msg_cb);

( $X = Sybase::CTlib->ct_connect($Uid, $Pwd, $Srv, '', {CON_PROPS => {CS_BULK_LOGIN => CS_TRUE}}) )
    and print("ok 2\n")
    or print "not ok 2
-- The supplied login id/password combination may be invalid\n";

$X->{UseBin0x} = 0;

$X->ct_sql("create table #tmp(x numeric(9,0) identity, a1 varchar(10), i int null, n numeric(6,2), d datetime, s smalldatetime, mn money, mn1 smallmoney, b varbinary(8), img image null)");

($X->blk_init("#tmp", 10, 0, 1) == CS_SUCCEED)
    and print "ok 3\n"
    or print "not ok 3\n";

@data = ([undef, "one", 123, 123.4, 'Oct 11 2001 11:00', 'Oct 11 2001', 23.456789, 44.23, 'deadbeef', 'x' x 1000],
	 [undef, "two", -1, 123.456, 'Oct 12 2001 11:23', 'Oct 11 2001', 44444444444.34, 44353.44, '0a0a0a0a', 'a' x 100],
	 [undef, "three", undef, 1234.78, 'Oct 11 2001 11:00', 'Oct 11 2001', 343434.3333, 34.23, '20202020', 'z' x 100]);

$i = 4;

# Verbose cs_convert() error messages.
#Sybase::CTlib::debug((1<<8));

foreach (@data) {
  $_->[8] = pack('H*', $_->[8]);
  ($X->blk_rowxfer($_) == CS_SUCCEED)
    and print "ok $i\n"
      or print "not ok $i\n";
    ++$i;
}

($X->blk_done(&Sybase::CTlib::CS_BLK_ALL, $rows) == CS_SUCCEED)
    and print "ok $i\n"
    or print "not ok $i\n";

++$i;
($rows == 3) and print "ok $i\n" or print "not ok $i\n";

$X->blk_drop;

++$i;

# Now test conversion failures. None of these rows should get loaded.
($X->blk_init("#tmp", 10, 0, 1) == CS_SUCCEED)
    and print "ok $i\n"
    or print "not ok $i\n";

++$i;

@data = ([undef, "one b", 123, 123.4, 'feb 29 2001 11:00', 'Oct 11 2001', 23.456789, 44.23, 'deadbeef', 'x' x 100],
	 [undef, "two b", 123456789123456, 123.456, 'Oct 12 2001 11:23', 'Oct 11 2001', 44444444444.34, 44353.44, '0a0a0a0a', 'a' x 100],
	 [undef, "three b", undef, 123456.78, 'Oct 11 2001 11:00', 'Oct 11 2001', 343434.3333, 34.23, '20202020', 'z' x 100],
	 [undef, "four b", undef, 126.78, 'Oct 11 2001 11:00', 'Oct 11 2001', 343434.3333, "34343434343434343434.23", '21212121', 'z' x 100],
	);

foreach (@data) {
  $_->[8] = pack('H*', $_->[8]);
  ($X->blk_rowxfer($_) != CS_SUCCEED)
    and print "ok $i\n"
      or print "not ok $i\n";
    ++$i;
}

($X->blk_done(&Sybase::CTlib::CS_BLK_ALL, $rows) == CS_SUCCEED)
    and print "ok $i\n"
    or print "not ok $i\n";

++$i;
($rows == 0) and print "ok $i\n" or print "not ok $i\n";

$X->blk_drop;

++$i;

($X->blk_init("#tmp", 10, 1, 0) == CS_SUCCEED)
    and print "ok $i\n"
    or print "not ok $i\n";

@data = ([10, "one", 123, 123.4, 'Nov 1 2001 12:00', 'Nov 1 2001', 343434.3333, 34.23, 'deadbeef', 'z' x 100],
	 [11, "two", -1, 123.456, '11/1/2001 12:00', '11/1/2001 11:21', 343434.3333, 34.23, '25252525', 'z' x 100],
	 [12, "three", undef, 123, 'Nov 1 2001 12:00', 'Nov 1 2001', 343434.3333, 34.23, '43434343', 'z' x 100]);

++$i;

foreach (@data) {
  $_->[8] = pack('H*', $_->[8]);
  print $_->[1], "\n";
    ($X->blk_rowxfer($_) == CS_SUCCEED)
	and print "ok $i\n"
	    or print "not ok $i\n";
    ++$i;
}

($X->blk_done(&Sybase::CTlib::CS_BLK_ALL, $rows) == CS_SUCCEED)
    and print "ok $i\n"
    or print "not ok $i\n";

++$i;
($rows == 3) and print "ok $i\n" or print "not ok $i\n";

$X->blk_drop;

#$X->{UseBinary} = 1;

$X->ct_sql("select * from #tmp", sub { local $^W = 0; print "@_\n"; });


sub srv_cb {
  local $^W = 0;
    print "@_\n";

    CS_SUCCEED;
}

sub clt_cb {
    local $^W = 0;
    print "@_\n";

    CS_SUCCEED;
}

sub msg_cb {
  my ($layer, $origin, $severity, $number, $msg, $osmsg, $usermsg) = @_;

  print "$layer $origin $severity $number: $msg ($usermsg)\n";

  if($number == 36) {
    return CS_SUCCEED;
  }

  return CS_FAIL;
}
