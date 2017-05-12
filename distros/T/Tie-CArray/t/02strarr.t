# CStringArray
use Test;
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);
BEGIN { plan tests => 19 }

use Tie::CArray;
use strict;
my $n = 10;
my @s = map { sprintf "%d", $_ } (0..$n-1);

my $S = new Tie::CStringArray($n);
ok( $S );
ok( ref $S, 'Tie::CStringArray');

undef $S;
ok( !$S );

$S = Tie::CStringArray::new($n,\@s);
ok( $S );

my $failed = 0;
for my $j (0 .. $n-1) {
    my $val = $S->get($j);
    ($failed = 1, last)
		unless (($val == $s[$j]) && (ref $val eq ref $s[$j]));
}
ok( !$failed );

# should we check range check errors?
eval { $S->set($n,0) };
ok( index ($@, "index out of range") > -1);
eval { $S->set(-1,0) };
ok( index ($@, "index out of range") > -1);

# acceptable type coercion
eval { $S->set(1,5.0) };
ok( $S->get(1), '5');
eval { $S->set(2,5.0001) };
ok( $S->get(2), '5.0001');
eval { $S->set(2,6) };
ok( $S->get(2), '6');

# other accepted type coercions (but should NOT be used)
# some refs
eval { $S->set(0,[0]) };
ok( $S->get(0) ); # rv->av as int
eval { $S->set(0,{0,0}) };
ok( $S->get(0) ); # rv->hv as int
eval { $S->set(0,(0)) };
ok( $S->get(0), 0 );   # hmm.
{ no strict 'subs';
  open (FILE, '>-'); # STDOUT FileHandle
  eval { $S->set(0,\FILE) };
  ok( !$@ );
  close FILE;
  opendir (DIR, '.'); # DirHandle
  eval { $S->set(0,\DIR) };
  ok( !$@ );
  closedir DIR;
}

# correctly rejected types: hmm, this cannot be caught by eval...
#eval { $S->set(0,<*>) };
# this should be catched by CArray->set, not by Ptr->set
#print ((index ($@, "Argument") > -1) ? '' : 'not ' , "ok 17\n");

map { $S->set($_,$s[$_]) } (0..$n-1);
# print join ", ", map { $S->get($_) } (0..19)

# indirect sort
my @sorted = $S->isort($n);  # must be (0..$n-1)
$failed = 0;
for my $j (0 .. $n-1) {
    ($failed = 1, last) unless $sorted[$j] == $j; }
ok( !$failed );

# grouping
# this should search the ISA, inherited from CArray::CPtr
my @s2 = $S->get_grouped_by(2,1);
$failed = ($s2[0] != $s[2] or
           $s2[1] != $s[3] or
           $#s2 != 1);
ok( !$failed );

$S->nreverse();
my $s = join ',', map {$S->get($_)} (0..$n-1);
ok( $s, join(',', reverse @s));

undef $S;
ok( !$S );