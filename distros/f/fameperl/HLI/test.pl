#!../../perl
# FT 7/23/97


use Fame;

# change packages to avoid having to write long package names
# for fxns

package Fame::HLI;

# unbuffered output
$|=1;

# remove a test database
system("rm test.db") if -e "test.db";

#
# Fame::HLI
#

print "Fame::HLI....ok\n";

$k=&fameopen("test.db",&HCMODE);
die "open failed [$Fame::HLI::status]" if $k==-1;

$f = &HDAILY;

eval { $n=&hli_freq($f); if ($n eq "") {print "FRB error\n"; $errors++;} };
print "FRB extensions not loaded--not a problem\n" if $@;

eval { $n=&getfrq($f); if ($n eq "") {print "HLILIB error\n"; $errors++;} };
print "HLILIB extensions not loaded--not a problem\n" if $@;

print "dates......";
# test dates
&cfmddat($stat,&HDAILY,$date,1993,5,2);
die "DATE FAILED date prob 1" if $stat != &HSUCC;
&cfmdatd($stat,&HDAILY,$date,$y,$m,$d);
die "DATE FAILED date prob 2" if $stat != &HSUCC;
&cfmddat($stat,&HDAILY,$date2,$y,$m,$d);
die "DATE FAILED date prob 3" if $stat != &HSUCC;
die "DATE FAILED date prob 4" if $date2!=$date;
print "ok\n";

#
# WRITING NUMERIC
#

# create a new object
$name="t1";
&cfmnwob($stat,$k,$name,&HSERIE,&HDAILY,
         &HNUMRC,&HBSDAY,&HOBBEG);

# get the object's information
@d=&famegetinfo($k,$name);

# write some data to the new object
@data=(5,4,3,7,1,2,7,4,3,5,4,6,7,4,2,8,6,4,5,4);

print "writing numeric series....";
$stat = &famewrite($k,$name,1990,1,@data);
if ($stat) {
  print "WRITE FAILED ($stat) !!!\n";
  $errors++;
}
# post
&cfmpodb($stat,$k);
print "ok\n";

# get the object's information
@d=&famegetinfo($k,$name);
# print "Info $name ($k): ",join(",",@d),"\n";

# read that data back
print "reading....";
@l=&fameread($k,$name,$d[5],$d[6],$d[7],$d[8]);

$flag=0;
foreach $x (0..$#data) {
  $flag++ if $data[$x] != $l[$x];
}
if ($flag>0) {
  print "READ/WRITE FAILED for $flag items!\n";
  $errors++;
}
else {
  print "ok\n";
}

#
# WRITING STRINGS
#

# create a new object
$name="t2";
&cfmnwob($stat,$k,$name,&HSERIE,&HDAILY,
         &HSTRNG,&HBSDAY,&HOBBEG);

@data=("One", "Two", "Three");
print "writing string series....";
$stat = &famewrite($k,$name,1990,1,@data);
if ($stat) {
  print "WRITE FAILED ($stat) !!!\n";
  $errors++;
}
# post
&cfmpodb($stat,$k);
print "ok\n";

@d=&famegetinfo($k,$name);
print "reading.....";
@l=&fameread($k,$name,$d[5],$d[6],$d[7],$d[8]);

$flag=0;
foreach $x (0..$#data) {
  $flag++ if $data[$x] ne $l[$x];
  #print "$data[$x]:$l[$x]:\n";
}

if ($flag>0) {
  print "READ/WRITE STRING FAILED for $flag items [$status]!\n";
  $errors++;
}
else {
  print "ok\n";
}

#
# status code
#

print "status codes.....";
$s = &cfmcpob($stat, $k, $k, "abcdefg", "testxyz");
if ($s==0 || $stat==0 || $stat != $s) {
  print "ERROR returning correct status\n";
  $errors++;
}
print "ok\n";

# close
print "closing.....";
if (! &fameclose($k)) {
  print "ERROR closing test database [$Fame::HLI::status]\n";
  $errors++;
}
print "ok\n";

#
# Fame::DB
#

print "Fame::DB Read/Write....";
$p=new Fame::DB "test", &Fame::HLI::HUMODE;
if ($p) {
  $p->Write($name,@data);
  @l = $p->Read($name);
  $flag=0;
  foreach $x (0..$#i-1) {
    $flag++ if $data[$x] != $l[$x];
  }
  if ($flag>0) {
    print "FAILED for $flag items!\n";
    $errors++;
  } else { print "ok\n"; }
  $p->destroy;
}
else {
  print "\nFAILED to open Fame::DB test database [$Fame::HLI::status]\n";
  $errors++;
}

print "Fame::DB TIE.....";
tie %h, Fame::DB, &Fame::HLI::HUMODE, "test";
$h{$name} = \@data;
@l = @{$h{$name}};
$flag=0;
foreach $x (0..$#i-1) {
  $flag++ if $data[$x] != $l[$x];
}
if ($flag>0) {
  print "FAILED for $flag items!\n";
  $errors++;
} else { print "ok\n"; }
untie %h;

#
# Fame::LANG
#

print "Fame::LANG.....";
$x=new Fame::LANG;
if ($x->{status} != &Fame::HLI::HSUCC) {
  print "FAILED to open new object\n";
  $errors++;
}
if ($x->command("open test")->{status} != &Fame::HLI::HSUCC) {
  print "FAILED command() for open\n";
  $errors++;
}
if ($x->command("x=15")->{status} != &Fame::HLI::HSUCC) {
  print "FAILED command() for x=15\n";
  $errors++;
}
($v)=$x->exec("x");
if ($v != 15) {
  print "FAILED exec() [v=$v]!\n";
  $errors++;
} else { print "ok\n"; }
$x->command("close all");
$x->destroy;

#
# terminte
#

if ($errors) {
  print "ERRORS FOUND! See test.db\n";
  exit($errors);
}

print "All tests ok\n";
system("rm test.db");
exit(0);
