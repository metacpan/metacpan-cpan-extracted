# -*- Mode: CPerl -*-
# t/04_storable.t: test storable subclasses

use lib qw(. ..); ##-- for debugging

use Test::More tests=>20;
my $TEST_DIR = ".";

use Tie::File::Indexed::Storable;
use Tie::File::Indexed::StorableN;
use Tie::File::Indexed::Freeze;
use Tie::File::Indexed::FreezeN;

##-- common variables
my $file = "$TEST_DIR/test_storable.dat";
my @w = (undef, \undef, \'string', \42, \24.7, {label=>'hash'}, [qw(a b c)], \{label=>'hash-ref'}, \[qw(d e f)]);

##-- 1+(4*5): json data
foreach my $sub (qw(Storable StorableN Freeze FreezeN)) {
  my $class = "Tie::File::Indexed::$sub";
  ok(tie(@a, $class, $file, mode=>'rw'), "$sub: tie");
  @a = @w;

  is($#a, $#w, "$sub: size");
  is_deeply(\@a,\@w, "$sub: content");

  my $gap = @a;
  $a[$gap+1] = \'post-gap';
  is($a[$gap], undef, "$sub: gap ~ undef");

  ok(tied(@a)->unlink, "$sub: unlink");
  untie(@a);
}

# end of t/05_storable.t
