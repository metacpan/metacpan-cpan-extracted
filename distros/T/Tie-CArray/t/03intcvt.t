# IntArray conversions
use Test;
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

BEGIN { plan tests => 24,
#		todo => [ 11,16,19,24 ],	# fixed
	  }

use Tie::CArray;
use strict;
use vars qw( $n $failed @i $I $I2 $I3 $I4 @rev @i $i2 @i2);

my $n = 20; my @i = (0..$n-1); my $failed;

my @rev = reverse @i;
my $I = new Tie::CIntArray($n,\@rev);

# convert to Int2
my $I2 = $I->ToInt2 (Tie::CIntArray->new($n,\@i));
ok( $I2 );
ok( ref $I2, 'Tie::CInt2Array');

# return into scalar context
$failed = 0;
for my $j (0 .. $n-1) {
    $i2 = $I2->get($j);
    ($failed = 1, last)
        unless (scalar @$i2 == 2 and
                $$i2[0] == $rev[$j] and
                $$i2[1] == $i[$j]);
}
ok( !$failed );			# 3

# list context
$failed = 0;
for my $j (0 .. $n-1) {
    @i2 = $I2->get($j);
    ($failed = 1, last)
        unless (@i2 == 2 and
                $i2[0] == $rev[$j] and
                $i2[1] == $i[$j]);
}
ok( !$failed );			# 4

$I2->set(3,[1,2]);
ok( join(',', $I2->get(3)), '1,2');	# 5

$I2 = new Tie::CInt2Array ($n);  # FIXME ::new will fail!
ok( $I2 );                          # 6
ok( ref $I2, 'Tie::CInt2Array');    # 7

for my $j (0 .. $n-1) {
    $I2->set($j,[$n-$j,$j]);
    $i2 = $I2->get($j);
    ($failed = 1, last)
        unless (scalar @$i2 == 2 and
                $$i2[0] == $n-$j and
                $$i2[1] == $j);
}
ok( !$failed );

# convert to Int3
my $I3 = $I->ToInt3 (new Tie::CIntArray($n,\@i),
                     new Tie::CIntArray($n,\@i));
ok( $I3 );
ok( ref $I3, 'Tie::CInt3Array');

$failed = 0;
for my $j (0 .. $n-1) {
    my $i3 = $I3->get($j);
    unless (scalar @$i3 == 3 and
            $$i3[0] == $rev[$j] and
            $$i3[1] == $i[$j]   and
            $$i3[2] == $i[$j])
    { $failed=1; last; }
}
ok( !$failed );			# 11

$failed = 0;
for my $j (0 .. $n-1) {
    my @i3 = $I3->get($j);
    unless (scalar @i3 == 3 and
            $i3[0] == $rev[$j] and
            $i3[1] == $i[$j]   and
            $i3[2] == $i[$j])
    { $failed=1; last; }
}
ok( !$failed );

$I3->set(0,[1,2,3]);
ok( join(',', $I3->get(0)), '1,2,3');

$I3 = new Tie::CInt3Array($n);
ok( $I3 );
ok( ref $I3, 'Tie::CInt3Array');

for my $j (0 .. $n-1) {
    $I3->set($j,[$n-$j,0,$j]);
    my $i3 = $I3->get($j);
    ($failed = 1, last)
        unless (@$i3 == 3 and
                $$i3[0] == $n-$j and
                $$i3[1] == 0 and
                $$i3[2] == $j);
}
ok( !$failed );			# 16

# convert to Int4
my $I4 = $I->ToInt4 (new Tie::CIntArray($n,\@i),
                     new Tie::CIntArray($n,\@i),
                     new Tie::CIntArray($n,\@i));
ok( $I4 );
ok( ref $I4, 'Tie::CInt4Array');

$failed = 0;
for my $j (0 .. $n-1) {
    my $i4 = $I4->get($j);
    unless (@$i4 == 4 and
            $$i4[0] == $rev[$j] and
            $$i4[1] == $i[$j] and
            $$i4[2] == $i[$j] and
            $$i4[3] == $i[$j])
    { $failed=1; last; }
}
ok( !$failed );		# 19

$failed = 0;
for my $j (0 .. $n-1) {
    my @i4 = $I4->get($j);
    unless (scalar @i4 == 4 and
            $i4[0] == $rev[$j] and
            $i4[1] == $i[$j] and
            $i4[2] == $i[$j] and
            $i4[3] == $i[$j])
    { $failed=1; last; }
}
ok( !$failed );

$I4->set(0,[1,2,3,4]);
ok( join (',', $I4->get(0)), '1,2,3,4');

$I4 = new Tie::CInt4Array($n);
ok( $I4 );
ok( ref $I4, 'Tie::CInt4Array');

for my $j (0 .. $n-1) {
    $I4->set($j,[$n-$j,0,$j,1]);
    my $i4 = $I4->get($j);
    unless (@$i4 == 4 and
            $$i4[0] == $n-$j and
            $$i4[1] == 0 and
            $$i4[2] == $j and
            $$i4[3] == 1)
    { $failed=1; last; }
}
ok( !$failed );			# 24
