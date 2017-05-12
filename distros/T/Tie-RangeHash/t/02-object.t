#-*- mode: perl;-*-

# General tests using the object-oriented interface for Tie::RangeHash

require 5.006;

use Test::More tests => 170;

use_ok("Tie::RangeHash");

ok($Tie::RangeHash::VERSION >= 1.03);

{
  my $node1 = new Tie::RangeHash::TYPE_NUMBER;
  ok( $node1->isa("Algorithm::SkipList::Node") );
  ok( $node1->isa("Algorithm::SkipList::NumericRangeNode") );

  my $node2 = new Tie::RangeHash::TYPE_STRING;
  ok( $node2->isa("Algorithm::SkipList::Node") );
  ok( $node2->isa("Algorithm::SkipList::StringRangeNode") );
}

{
  my $hash = new Tie::RangeHash Type => Tie::RangeHash::TYPE_NUMBER;
  ok( $hash->isa("Tie::RangeHash") );
  ok( ref($hash) eq "Tie::RangeHash" );

  my @ranges = qw( 1 3 5 7 9 11 );
  my @keys   = ( );
  my $count  = 0;

  my $last_hi = undef;
  while (my $low = shift @ranges) {
    my $high = shift @ranges;

    my $key = "$low,$high";
    push @keys, $key;
    
    $hash->add($key, ++$count);
    ok($hash->fetch_key($key) eq $key);
    ok($hash->fetch_key($low) eq $key);
    ok($hash->fetch_key($high) eq $key);
    ok($hash->fetch($key) == $count);
    ok($hash->fetch($low) == $count);
    ok($hash->fetch($high) == $count);
    if ($low != $high) {
      ok($hash->fetch_key($low+1) eq $key);
      ok($hash->fetch_key($high-1) eq $key);
      ok($hash->fetch($low+1) == $count);
      ok($hash->fetch($high-1) == $count);
    }
    ok(!defined $hash->fetch($low-1));

    if (defined $last_hi) {
      my $result = 0;
      eval{
	$hash->add("$last_hi,$low", -1);
	$result = $hash->fetch("$last_hi,$low");
      };
      ok(!$result);
    }
    $last_hi = $high;
  }

  {
    my @values = $hash->fetch_overlap("1,11");
    ok(@values == 3);

    @values = $hash->fetch_overlap("0,11");
    ok(@values == 3);

    @values = $hash->fetch_overlap("0,12");
    ok(@values == 3);

    @values = $hash->fetch_overlap("1,6");
    ok(@values == 2);

    @values = $hash->fetch_overlap("1,2");
    ok(@values == 1);

    @values = $hash->fetch_overlap("0,2");
    ok(@values == 1);

    @values = $hash->fetch_overlap("10,100");
    ok(@values == 1);
  }

  $hash->add(",-1", 0);        unshift @keys, ",-1";
  $hash->add("13,", ++$count); push    @keys, "13,";

  ok($hash->fetch(-4000) == 0, "open-ended ranges");
  ok($hash->fetch( 4000) == $count);


  while (my $key = $hash->next_key) {
    ok($key eq shift @keys, "next_key");
    push @keys, $key;
  }

  $hash->reset;
  ok($hash->next_key eq $hash->first_key, "next_key returns first_key");

  ok($hash->size > 0);
  $hash->clear;
  ok($hash->size == 0, "clear");

  $count = 0;
  foreach my $key (@keys) {
    $hash->add($key, ++$count);
    ok($hash->size == $count);
    ok($hash->key_exists($key));
    ok($hash->fetch($key) == $count);
  }

  $count = 0;
  while (my $key = shift @keys) {
    ok(++$count == $hash->remove($key), "remove");
    ok(!defined $hash->fetch($key));
    ok($hash->size == @keys);
  }
}

{

  sub succ {
    return pack "C", (unpack "C", shift)+1;
  }

  sub pred {
    return pack "C", (unpack "C", shift)-1;
  }

  ok(succ("A") eq "B", "succ()");
  ok(pred("B") eq "A", "pred()");
  ok(succ(pred("A")) eq pred(succ("A")));

  my $hash = new Tie::RangeHash Type => Tie::RangeHash::TYPE_STRING;
  ok( $hash->isa("Tie::RangeHash") );
  ok( ref($hash) eq "Tie::RangeHash" );

  my @ranges = qw( A C E G I K );
  my @keys   = ( );
  my $count  = 0;

  my $last_hi = undef;
  while (my $low = shift @ranges) {
    my $high = shift @ranges;

    my $key = "$low,$high";
    push @keys, $key;
    
    $hash->add($key, ++$count);
    ok($hash->fetch_key($key) eq $key);
    ok($hash->fetch_key($low) eq $key);
    ok($hash->fetch_key($high) eq $key);
    ok($hash->fetch($key) == $count);
    ok($hash->fetch($low) == $count);
    ok($hash->fetch($high) == $count);
    if ($low ne $high) {
      ok($hash->fetch_key(succ($low)) eq $key);
      ok($hash->fetch_key(pred($high)) eq $key);
      ok($hash->fetch(succ($low)) == $count);
      ok($hash->fetch(pred($high)) == $count);
    }
    ok(!defined $hash->fetch(pred($low)));

    if (defined $last_hi) {
      my $result = 0;
      eval{
	$hash->add("$last_hi,$low", -1);
	$result = $hash->fetch("$last_hi,$low");
      };
      ok(!$result);
    }
    $last_hi = $high;
  }
  $hash->add(",".(pred(pred("A"))), 0); unshift @keys, ",".(pred(pred("A")));
  $hash->add("M,", ++$count);           push    @keys, "M,";

  ok($hash->fetch(  "-") == 0, "open-ended ranges");
  ok($hash->fetch("ZZZ") == $count);

  while (my $key = $hash->next_key) {
    ok($key eq shift @keys, "next_key");
    push @keys, $key;
  }

  $hash->reset;
  ok($hash->next_key eq $hash->first_key, "next_key returns first_key");

  ok($hash->size > 0);
  $hash->clear;
  ok($hash->size == 0, "clear");

  $count = 0;
  foreach my $key (@keys) {
    $hash->add($key, ++$count);
    ok($hash->size == $count);
    ok($hash->key_exists($key));
    ok($hash->fetch($key) == $count);
  }

  $count = 0;
  while (my $key = shift @keys) {
    ok(++$count == $hash->remove($key), "remove");
    ok(!defined $hash->fetch($key));
    ok($hash->size == @keys);
  }


}
