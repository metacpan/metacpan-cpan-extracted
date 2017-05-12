# CDoubleArray's with function and OO method syntax,

# currently fails: 06:28 05.12.99
# none

use Tie::CArray;
use strict;
local $^W = 1;
print "1..25\n";
my $n = 200; my @d = map { $_ + 0.01 } (0 .. $n-1);

my $D = new Tie::CDoubleArray($n,\@d);
print $D ? "" : "not " , "ok 1\n";
print ref($D) eq 'Tie::CDoubleArray' ? "" : "not ", "ok 2\n";

print "not "
  unless ($D->itemsize > 0 and $D->itemsize == $Tie::CDoubleArray::itemsize);
print "ok 3\n";

my $failed = 0;
for my $j (0 .. $n-1) {
    my $val = $D->get($j);
    ($failed = 1, last) unless (($val == $d[$j]) && (ref $val eq ref $d[$j]));
}
print $failed ? "not ": "" , "ok 4\n";

undef $D;
print $D ? "not ": "" , "ok 5\n"; # still alive

$D = Tie::CDoubleArray->new($n);
print $D ? "" : "not " , "ok 6\n";

map { $D->set($_, $d[$_]) } (0.. $n-1);
$failed = 0;
for my $j (0 .. $n-1) {
    my $val = $D->get($j);
    ($failed = 1, last) unless (($val == $d[$j]) && (ref $val eq ref $d[$j]));
}
print $failed ? "not ": "" , "ok 7\n";

# should we check range check errors?
eval { $D->set($n,0) };
print ((index ($@, "index out of range") > -1) ? "" : "not " , "ok 8\n");
eval { $D->set(-1,0) };
print ((index ($@, "index out of range") > -1) ? "" : "not " , "ok 9\n");

# acceptable type coercion
eval { $D->set(0,5) };
print $D->get(0) == 5.0 ? "" : "not " , "ok 10\n";
eval { $D->set(0,"6") };
print $D->get(0) == 6 ? "" : "not " , "ok 11\n";

# other accepted type coercions (but should NOT be used)
# some refs
eval { $D->set(0,[0]) };
print $D->get(0) ? "" : "not " , "ok 12\n";      # rv->av as int
eval { $D->set(0,{0,0}) };
print $D->get(0) ? "" : "not " , "ok 13\n";      # rv->hv as int
eval { $D->set(0,(0)) };
print $D->get(0) == 0 ? "" : "not " , "ok 14\n"; # hmm.
{ no strict 'subs';
  open (FILE, '>-'); # STDOUT FileHandle
  eval { $D->set(0,\FILE) };
  print $@ ? "not " : "" , "ok 15\n";
  close FILE;
  opendir (DIR, '.'); # DirHandle
  eval { $D->set(0,\DIR) };
  print $@ ? "not " : "" , "ok 16\n";
  closedir DIR;
}

# correctly rejected types: hmm, this cannot be caught by eval...
#eval { $D->set(0,<*>) };
# this should be catched by CArray->set, not by Ptr->set
#print ((index ($@, "Argument") > -1) ? "" : "not " , "ok 17\n");

# fastest way to fill it, besides passing a reference at new?
my $j = 0;
map { $D->set($j++,$_) } @d;
#print join ',', map { $D->get($_) } (0..$n-1);
my $s = join ',', map { $D->get($_) } (0..$n-1);
print $s eq (join ',', @d) ? "": "not " , "ok 17\n";

# indirect sort
my @sorted = $D->isort($n);  # must be (0..$n-1)
$failed = 0;
for my $j (0 .. $n-1) {
    ($failed = 1, last) unless $sorted[$j] == $j; }
print $failed ? "not ": "" , "ok 18\n";

# grouping
my @d2 = $D->get_grouped_by(2,1);
$failed = ($d2[0] != $d[2] or
           $d2[1] != $d[3] or
           $#d2 != 1);
print $failed  ? "not " : "" , "ok 19\n";

print join(',', $D->slice(1,3)) eq '1.01,2.01,3.01' ? "" : "not " , "ok 20\n";
print join(',', $D->slice(2,4)) eq '2.01,3.01,4.01,5.01' ? "" : "not " , "ok 21\n";
print join(',', $D->slice(1,3,3)) eq '1.01,4.01,7.01' ? "" : "not " , "ok 22\n";
print join(',', $D->slice(1,0)) eq '' ? "" : "not " , "ok 23\n";

# since 0.08, still fails at index 0
$D->nreverse();
$s = join ',', map {$D->get($_)} (0..$n-1);
print (($s eq join ',', reverse @d) ? "": "not " , "ok 24\n");

undef $D;
print $D ? "not ": "" , "ok 25\n"; # still alive