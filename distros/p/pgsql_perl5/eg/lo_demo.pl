#!/usr/local/bin/perl -w

use Pg;

$DBNAME   = 'lo_demo';
$PGIN     = '/tmp/pgin';
$PGOUT    = '/tmp/pgout';
$BUFSIZE = 8192;

open(PGIN, ">$PGIN");
foreach $ascii (0..255) {
  print PGIN chr($ascii)
};
close PGIN;

system('dropdb',$DBNAME);
system('createdb', $DBNAME);

$conn = Pg::setdb('localhost', 5432, ''  ,'' , $DBNAME);


$lobjId  = $conn->lo_creat(PGRES_INV_WRITE | PGRES_INV_READ);
die "can not create large object" if $lobjId == PGRES_InvalidOid;
print "lobjId = >$lobjId< \n";

$conn->exec("begin");
$lobj_fd = $conn->lo_open($lobjId, PGRES_INV_WRITE);
die "can not open lobjId for writing" if $lobj_fd == -1;
print "lobj_fd = >$lobj_fd< \n";
open(PGIN, $PGIN) or die "can not open $PGIN";
while ($nbytes = read(PGIN, $buf, $BUFSIZE)) {
  $tmp = $conn->lo_write($lobj_fd, $buf, $nbytes);
  die "error while reading from $PGIN: nbytes = $nbytes, tmp = $tmp" if $tmp < $nbytes;
  $sum += $nbytes;
}
close PGIN;
print "wrote $sum bytes into lobj_fd\n";

$conn->lo_close($lobj_fd);
$conn->exec("end");

$conn->exec("begin");
$lobj_fd = $conn->lo_open($lobjId, PGRES_INV_READ);
die "can not open lobjId for reading" if $lobj_fd == -1;

$sum = 0;
$buf = '';
open(PGOUT, ">$PGOUT") or die "can not open $PGOUT";
while (($nbytes = $conn->lo_read($lobj_fd, $buf, $BUFSIZE)) > 0) {
  print "read  $nbytes bytes rom blob \n";
  printf PGOUT "%${nbytes}s", $buf;
  $sum += $nbytes;
}
close PGOUT;
print "wrote $sum bytes into $PGOUT \n";

$conn->lo_close($lobj_fd);
$conn->exec("end");
$conn->lo_unlink($lobjId);
undef $conn;


system('dropdb',$DBNAME);

# EOF
