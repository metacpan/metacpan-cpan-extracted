#!/usr/bin/perl

use strict;

use lib "./lib";
use lib "./blib/lib";

use Time::localtime;

BEGIN { 
  $| = 1; 
  print "1..23\n"; 
  unlink("conf.cfg.lock");
}

sub ok {
  my $t=shift;
  my $a=shift;
  print "ok ",$t+$a,"\n";
}

sub nok {
  print "not ";ok(@_);
}

######################################################################

my %cfg;
my $again=0;
my $counter;
my $tests=11;

while ($again==0 or $again==$tests) {

######################################################################

print "test 1: using the module and tie this.\n";

use Tie::Cfg;
tie %cfg, 'Tie::Cfg', READ => "conf.cfg", WRITE => "conf.cfg", LOCK => 1, MODE => 0600;

ok(1,$again);

######################################################################

print "test 2: getting.\n";

for (1..10) {
  if (exists $cfg{$_}) {
    print $cfg{$_}," - ";
  }
  else {
    print "U - ";
  }
}
print "\n";
ok(2,$again);

######################################################################

print "test 3: setting.\n";

for (1..10) {
  $cfg{$_}=$_**2;
}

for (1..10) {
  print $cfg{$_}," - ";
}
print "\n";

ok(3,$again);

######################################################################

print "test 4: Checking if we have to run this test again.\n";

if (not exists $cfg{AGAIN}) {
  $cfg{AGAIN}="yes";
}

ok(4,$again);

######################################################################


print "test 5: closing.\n";

untie %cfg;

ok(5,$again);


######################################################################

print "test 6: reading /etc/passwd.\n";

my $user="";
my $empty="";

  $user=$ENV{USER};
  if (not $user) { $user=""; }

  if ($user eq $empty) {
    $user=$ENV{USERNAME};
    if (not $user) { $user=""; }
    if ($user eq "") {
      print "Trying whoami...\n";
      open IN,"whoami |";
      $user=<IN>;
      close IN;
      $user=~s/\s+$//;
    }
  }

  print "found user $user\n";

  if (not $user) {
    print "skipping 6\n";
  }
  else {
    tie %cfg,'Tie::Cfg', READ => "/etc/passwd", SEP => ':', COMMENT => '#';
    print "/etc/passwd entry for $user\n";
    print $cfg{$user},"\n";
    untie %cfg;

    ok(6,$again);
  }

######################################################################

print "test 7: Using ini mode and sections\n";

tie %cfg,'Tie::Cfg', READ => "sect.ini", WRITE => "sect.ini";

print "counter section1.par1=",$cfg{"section1"}{"par1"},"\n";
$counter=$cfg{"section1"}{"par1"};
$counter+=1;
$cfg{"section"}{"par1"}=$counter;
$cfg{"section1"}{"par1"}=$counter;

print "section.par1=",$cfg{"section"}{"par1"},"\n";
print "section1.par1=",$cfg{"section1"}{"par1"},"\n";

$cfg{"somekey"}=rand;
$cfg{"somesect"}{"somekey"}="jeo";

for my $v (@{$cfg{"array"}{"a"}}) {
	print "get a ",$v,"\n";
}


for (0..10) {
  $cfg{"array"}{"a"}[$_]=$cfg{"array"}{"a"}[$_]+$_;
}

for (0..10) {
	print "array[$_]=",$cfg{"array"}{"a"}[$_],"\n";
}

print "untie...\n";
untie %cfg;
print "untie done.\n";

ok(7,$again);

######################################################################

print "test 8: Using ini mode with user separator\n";

tie %cfg, 'Tie::Cfg', READ => "usersect.ini", WRITE => "usersect.ini", SEP => ":", COMMENT => "#", REGSEP => "[:]", REGCOMMENT => "[#]";

print "counter section1.par1",$cfg{"par1"},"\n";
$counter=$cfg{"par1"};
$counter+=1;
$cfg{"par1"}=$counter;

$cfg{"tochange"}="/thisisaprefix/tmp";

#$cfg{"tochange"}="PREFIX/tmp";
#{
#my $obj=tied %cfg;
#my $prefix="\/thisisaprefix";
#
#  print "prefix before change: ",$cfg{"tochange"},"\n";
#  $obj->change("/PREFIX/$prefix/");
#  print "prefix after change : ",$cfg{"tochange"},"\n";
#}
#
untie %cfg;
ok(8,$again);

######################################################################

print "test 9: read and write sect.ini\n";

tie %cfg, 'Tie::Cfg', READ => "sect.ini", WRITE => "sect.ini";
untie %cfg;

ok(9,$again);


######################################################################

print "test 10: recursive hashes in Cfg\n";

tie %cfg, 'Tie::Cfg', READ => "sect.ini", WRITE => "sect.ini";

$counter=$cfg{"counter"};
$counter+=1;

for my $i (1..10) {
	print "array[$i]=$i, ";
}
print "\n";

for my $i (1..2) {
	for my $j (1..2) {
		for my $k (1..2) {
			for my $l (1..2) {
				print "section$i.subsec$j.ssubsec$k.par$l=",$cfg{"section$i"}{"subsec$j"}{"ssubsec$k"}{"par$l"},"\n";
			}
			print "section$i.subsec$j.par$k=",$cfg{"section$i"}{"subsec$j"}{"par$k"},"\n";
		}
	}
}

for my $i (1..2) {
	for my $j (1..2) {
		for my $k (1..2) {
			for my $l (1..2) {
				$cfg{"section$i"}{"subsec$j"}{"ssubsec$k"}{"par$l"}=$counter;
			}
			$cfg{"section$i"}{"subsec$j"}{"par$k"}=$counter;
		}
	}
}


$counter+=1;
$cfg{"counter"}=$counter;

untie %cfg;
ok(10,$again);

######################################################################

print "test 11, testing locking\n";

#
# Never make a tied cfg file before using fork. The child will inherit
# the cfg and will free it double.
#

if (not fork()) {
  print "Child: waiting 2 seconds before start...\n";
  print "Child: trying to tie...\n";
  print "Child: ", ctime(),"\n";
  tie my %cfg, 'Tie::Cfg', READ => "conf.cfg", WRITE => "conf.cfg", LOCK => 1, MODE => 0600;
  print "Child: Got it at ",ctime(),", untieing...\n";
  untie %cfg;
  print "Child: released conf.cfg\n";
  exit;
}

tie %cfg, 'Tie::Cfg', READ => "conf.cfg", WRITE => "conf.cfg", LOCK => 1, MODE => 0600;
print "Parent: Has conf.cfg\n";

print "Parent: sleeping 5 seconds\n";
sleep 5;

print "Parent: giving free...\n";
untie %cfg;
print "Parent: released conf.cfg\n";

print "waiting for child to quit...\n";
wait;

ok(11,$again);

######################################################################

if (not $again) {
  print "\nRunning this test again (make test for the second time).\n";
  $again+=$tests;
}
else {
  $again+=$tests;
  print "\nYou're done.\n";
}

######################################################################
# Einde while

}

######################################################################

print "test 23: Change 'thisisa'  to THISISARTFMTHING\n";

tie %cfg, 'Tie::Cfg', READ => "usersect.ini", WRITE => "usersect.ini", SEP => ":", COMMENT => "#", REGSEP => "[:]", REGCOMMENT => "[#]", CHANGE => [ "s/thisisa/THISISARTFMTHING/" ];

print $cfg{"tochange"},"\n";

untie %cfg;

ok(23,0);

######################################################################

unlink("conf.cfg");
unlink("conf.cfg.lock");
unlink("sect.ini");
unlink("usersect.ini");

exit;
