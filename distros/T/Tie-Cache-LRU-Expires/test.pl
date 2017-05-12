#!/usr/bin/perl

BEGIN { $| = 1; print "1..7\n"; } 

print "test 1: using the module.\n";

use Tie::Cache::LRU::Expires;

print "ok 1\n";

print "test 2: setting and getting.\n";

tie %cache, 'Tie::Cache::LRU::Expires', ENTRIES => 5, EXPIRES => 3;
$cache_obj=tied %cache;

print "setting...\n";
for (1..10) {
  $cache{$_}="test $_";
}

print "getting...\n";
for (1..10) { if (defined $cache{$_}) { print "$_=",$cache{$_},"\n"; } }
print "entries in LRU cache:",$cache_obj->lru_size(),"\n";

$procesid="NTA.nl";
$adrtype="X.400, SMTP";
$entry=$procesid.$adrtype;
$cache{$entry}="Dit is gecached";
print "$entry: ",$cache{$entry},"\n";


$procesid="NTA.nl";
$adrtype="X.400,SMTP";
$entry=$procesid.$adrtype;
$cache{$entry}="Dit is gecached";
print "$entry: ",$cache{$entry},"\n";

$cache{"hans"}="Case insensitive?";
print "hans : ",$cache{"hans"}, "  Hans:", $cache{"Hans"}, "\n";

$datum1="20020331";
$datum2="20020404";
$datumdiff=$datum2-$datum1;
print "$datumdiff";

print "ok 2\n";

print "test 3: expiry test: setting...\n";
print "1..3 now, 4 and 5 two seconds later\n";
for (1..3) { $cache{$_}="test $_"; }
sleep 2;
for (4..5) { $cache{$_}="test $_ (2 secs apart)"; }

print "getting...\n";
for (1..10) { if (defined $cache{$_}) { print "$_=",$cache{$_},"\n"; } }
print "entries in LRU cache:",$cache_obj->lru_size(),"\n";

print "waiting 2 secs...\n";
sleep 2;

print "getting...\n";
for (1..10) { if (defined $cache{$_}) { print "$_=",$cache{$_},"\n"; } }
print "entries in LRU cache:",$cache_obj->lru_size(),"\n";

print "waiting another 2 secs...\n";
sleep 2;

print "getting...\n";
for (1..10) { if (defined $cache{$_}) { print "$_=",$cache{$_},"\n"; } }
print "entries in LRU cache:",$cache_obj->lru_size(),"\n";

print "ok 3\n";

print "test4: testing the caching of arrays (including expiry)\n";

print "initializing the array...\n";
$A=[ 'a', 'b', "c" ];
for (0..2) {
  $q=$A->[$_];
  print "array:$q\n";
}

print "putting the array in cache...\n";

$cache{"array"}=$A;

print "changing entry 1 (out of 0, 1, 2)...\n";
$A->[1]="jojo";

print "getting the cached entry...\n";
$W=$cache{"array"};
foreach $i ( @$W) {
  print "array:$i\n";
}
print "entries in LRU cache:",$cache_obj->lru_size(),"\n";

print "printing the original variable...\n";
foreach $i ( @$A) {
  print "array:$i\n";
}

print "putting an other array in cache (directly)...\n";

$cache{"hans"}=[ 1, 2, 3, 4];

print "getting the cached entry...\n";
$R=$cache{"hans"};
foreach $i ( @$R) {
  print "hans:$i\n";
}
print "entries in LRU cache:",$cache_obj->lru_size(),"\n";

print "waiting for 5 seconds...\n";
sleep 5;
$R=$cache{"hans"};
if (defined $R) {
  print "not expired?\n";
  print "not ok 4\n";
}
else { 
  print "expired\n";
  print "ok 4\n";
}

print "test 5, overwriting cached entries\n";

print "writing 'hans' entry two times...\n";
$cache{"hans"}="entry1";
print "result:",$cache{"hans"},"\n";
print "entries in LRU cache:",$cache_obj->lru_size(),"\n";
$cache{"hans"}="entry2";
print "result:",$cache{"hans"},"\n";
print "entries in LRU cache:",$cache_obj->lru_size(),"\n";

if ( $cache{"hans"} ne "entry2" ) {
  print "not";
}
print "ok 5\n";

print "test 6: checking existance\n";

$cache{"hans"}="entry";
if (exists $cache{"hans"}) {
  print "exists\n";
}
else {
  print "not ok 6\n";
  exit;
}

if (exists $cache{"transit"}) {
  print "not ok 6\n";
  exit;
}
else {
  print "doesn't exist\n";
}

print "entries in LRU cache:",$cache_obj->lru_size(),"\n";

print "waiting 5 seconds to check existance again\n";
sleep 5;

if (exists $cache{"hans"}) {
  print "not ok 6\n";
  exit;
}
else {
  print "doesn't exist anymore\n";
}

print "entries in LRU cache:",$cache_obj->lru_size(),"\n";

print "clearing LRU cache..\n";

%cache = ();

if (keys %cache == 0) {
	print "ok 7\n";
} else {
	print "not ok 7\n";
}

print "entries in LRU cache:",$cache_obj->lru_size(),"\n";
