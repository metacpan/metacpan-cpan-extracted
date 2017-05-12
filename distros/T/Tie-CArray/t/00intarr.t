# CIntArray's with function and OO method syntax,
use Test;
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

BEGIN { plan tests => 26 }

use Tie::CArray;
use strict;

my $n = 200; my @i = (0..$n-1);

my $I = new Tie::CIntArray($n,\@i);
ok( $I );
ok( ref($I), 'Tie::CIntArray' );

ok ($I->itemsize > 0);
ok ($I->itemsize,$Tie::CIntArray::itemsize);

my $failed = 0;
for my $j (0 .. $n-1) {
    my $val = $I->get($j);
    ($failed = 1, last)
		unless (($val == $i[$j]) && (ref $val eq ref $i[$j]));
}
ok( !$failed );

undef $I;
ok( !$I ); # still alive

$I = Tie::CIntArray->new($n);
ok( $I );

map { $I->set($_, $i[$_]) } (0.. $n-1);
$failed = 0;
for my $j (0 .. $n-1) {
    my $val = $I->get($j);
    ($failed = 1, last)
		unless (($val == $i[$j]) && (ref $val eq ref $i[$j]));
}
ok( !$failed );

# should we check range check errors?
eval { $I->set($n,0) };
ok (index($@, "index out of range") > -1);
eval { $I->set(-1,0) };
ok (index($@, "index out of range") > -1);

# acceptable type coercion
eval { $I->set(0,5.0) };
ok($I->get(0), 5);
eval { $I->set(0,"6") };
ok( $I->get(0), 6);

# other accepted type coercions (but should NOT be used)
# some refs
eval { $I->set(0,[0]) };
ok( $I->get(0) );      # rv->av as int
eval { $I->set(0,{0,0}) };
ok( $I->get(0) );      # rv->hv as int
eval { $I->set(0,(1)) };
ok( $I->get(0) );      # hmm.
{ no strict 'subs';
  open (FILE, '>-');   # STDOUT FileHandle
  eval { $I->set(0,\FILE) };
  ok !$@;
  close FILE;
  opendir (DIR, '.'); # DirHandle
  eval { $I->set(0,\DIR) };
  ok !$@;
  closedir DIR;
}

# fastest way to fill it, besides passing a reference at new?
my $j = 0;
map { $I->set($j++,$_) } @i;
#print join ',', map { $I->get($_) } (0..$n-1);
my $s = join ',', map { $I->get($_) } (0..$n-1);
ok ($s, join(',', @i));

# indirect sort
my @sorted = $I->isort($n);  # must be (0..$n-1)
$failed = 0;
for my $j (0 .. $n-1) {
    ($failed = 1, last) unless $sorted[$j] == $j; }
ok( !$failed );

# grouping
my @i2 = $I->get_grouped_by(2,1);
$failed = ($i2[0] != $i[2] or
           $i2[1] != $i[3] or
           $#i2 != 1);
ok( !$failed );

ok( join(',', $I->slice(1,3)), '1,2,3');
ok( join(',', $I->slice(2,4)), '2,3,4,5');
ok( join(',', $I->slice(1,3,3)), '1,4,7');
ok( join(',', $I->slice(1,0)), '');

# since 0.08, still fails at index 0
$I->nreverse();
$s = join ',', map {$I->get($_)} (0..$n-1);
ok ($s, join(',', reverse @i));

undef $I;
ok( !$I );