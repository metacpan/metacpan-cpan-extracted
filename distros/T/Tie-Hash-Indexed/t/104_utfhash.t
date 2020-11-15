#!./perl -w
use Test;
use Tie::Hash::Indexed;
use strict;

BEGIN {
  plan tests => 97;

  if ($] < 5.008) {
    for (1..97) {
      skip("No UTF8 support", 0, 0);
    }
    exit 0;
  }
}

# Two hashes one will all keys 8-bit possible (initially), other
# with a utf8 requiring key from the outset.

tie my %hash8, 'Tie::Hash::Indexed';
%hash8 = ( "\xff" => 0xff,
           "\x7f" => 0x7f,
         );
tie my %hashu, 'Tie::Hash::Indexed';
%hashu = ( "\xff" => 0xff,
           "\x7f" => 0x7f,
           "\x{1ff}" => 0x1ff,
         );

# Check that we can find the 8-bit things by various literals
ok($hash8{"\x{00ff}"},0xFF);
ok($hash8{"\x{007f}"},0x7F);
ok($hash8{"\xff"},0xFF);
ok($hash8{"\x7f"},0x7F);
ok($hashu{"\x{00ff}"},0xFF);
ok($hashu{"\x{007f}"},0x7F);
ok($hashu{"\xff"},0xFF);
ok($hashu{"\x7f"},0x7F);

# Now try same thing with variables forced into various forms.
foreach my $a ("\x7f","\xff") {
  utf8::upgrade($a);
  ok($hash8{$a},ord($a));
  ok($hashu{$a},ord($a));
  utf8::downgrade($a);
  ok($hash8{$a},ord($a));
  ok($hashu{$a},ord($a));
  my $b = $a.chr(100);
  chop($b);
  ok($hash8{$b},ord($b));
  ok($hashu{$b},ord($b));
}

# Check we have not got an spurious extra keys
ok(join('',sort { ord $a <=> ord $b } keys %hash8),"\x7f\xff");
ok(join('',sort { ord $a <=> ord $b } keys %hashu),"\x7f\xff\x{1ff}");

# Now add a utf8 key to the 8-bit hash
$hash8{chr(0x1ff)} = 0x1ff;

# Check we have not got an spurious extra keys
ok(join('',sort { ord $a <=> ord $b } keys %hash8),"\x7f\xff\x{1ff}");

foreach my $a ("\x7f","\xff","\x{1ff}") {
  utf8::upgrade($a);
  ok($hash8{$a},ord($a));
  my $b = $a.chr(100);
  chop($b);
  ok($hash8{$b},ord($b));
}

# and remove utf8 from the other hash
ok(delete $hashu{chr(0x1ff)},0x1ff);
ok(join('',sort keys %hashu),"\x7f\xff");

foreach my $a ("\x7f","\xff") {
  utf8::upgrade($a);
  ok($hashu{$a},ord($a));
  utf8::downgrade($a);
  ok($hashu{$a},ord($a));
  my $b = $a.chr(100);
  chop($b);
  ok($hashu{$b},ord($b));
}

{
  print "# Unicode hash keys and \\w\n";
  # This is not really a regex test but regexes bring
  # out the issue nicely.
  use strict;
  my $u3 = "f\x{df}\x{100}";
  my $u2 = substr($u3,0,2);
  my $u1 = substr($u2,0,1);
  my $u0 = chr (0xdf)x4; # Make this 4 chars so that all lengths are distinct.

  my @u = ($u0, $u1, $u2, $u3);

  while (@u) {
    my %u = (map {( $_, $_)} @u);
    my $keys = scalar @u;
    $keys .= ($keys == 1) ? " key" : " keys";

    for (keys %u) {
      my $l = 0 + /^\w+$/;
      my $r = 0 + $u{$_} =~ /^\w+$/;
      ok($l, $r, "\\w on keys with $keys, key of length " . length $_);
    }

    my $more;
    do {
      $more = 0;
      # Want to do this direct, rather than copying to a temporary variable
      # The first time each will return key and value at the start of the hash.
      # each will return () after we've done the last pair. $more won't get
      # set then, and the do will exit.
      for (each %u) {
        $more = 1;
        my $l = 0 + /^\w+$/;
        my $r = 0 + $u{$_} =~ /^\w+$/;
        ok($l, $r, "\\w on each, with $keys, key of length " . length $_);
      }
    } while ($more);

    for (%u) {
      my $l = 0 + /^\w+$/;
      my $r = 0 + $u{$_} =~ /^\w+$/;
      ok($l, $r, "\\w on hash with $keys, key of length " . length $_);
    }
    pop @u;
    undef %u;
  }
}

{
  my $utf8_sz = my $bytes_sz = "\x{df}";
  $utf8_sz .= chr 256;
  chop ($utf8_sz);

  my (%bytes_first, %utf8_first);

  $bytes_first{$bytes_sz} = $bytes_sz;

  for (keys %bytes_first) {
    my $l = 0 + /^\w+$/;
    my $r = 0 + $bytes_first{$_} =~ /^\w+$/;
    ok($l, $r, "\\w on each, bytes");
  }

  $bytes_first{$utf8_sz} = $utf8_sz;

  for (keys %bytes_first) {
    my $l = 0 + /^\w+$/;
    my $r = 0 + $bytes_first{$_} =~ /^\w+$/;
    ok($l, $r, "\\w on each, bytes now utf8");
  }

  $utf8_first{$utf8_sz} = $utf8_sz;

  for (keys %utf8_first) {
    my $l = 0 + /^\w+$/;
    my $r = 0 + $utf8_first{$_} =~ /^\w+$/;
    ok($l, $r, "\\w on each, utf8");
  }

  $utf8_first{$bytes_sz} = $bytes_sz;

  for (keys %utf8_first) {
    my $l = 0 + /^\w+$/;
    my $r = 0 + $utf8_first{$_} =~ /^\w+$/;
    ok($l, $r, "\\w on each, utf8 now bytes");
  }

}

{
  # See if utf8 barewords work [perl #22969]
  use utf8;
  my %hash;
  my $bare = $] < 5.008001 ? 'skip: no utf8 barewords' : '';
  tie %hash, 'Tie::Hash::Indexed';
  %hash = (тест => 123);
  skip($bare, $hash{тест}, $hash{'тест'});
  skip($bare, $hash{тест}, 123);
  ok($hash{'тест'}, 123);
  %hash = (тест => 123);
  skip($bare, $hash{тест}, $hash{'тест'});
  skip($bare, $hash{тест}, 123);
  ok($hash{'тест'}, 123);
}
