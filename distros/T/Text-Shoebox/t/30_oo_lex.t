
# Time-stamp: "2004-04-03 20:23:17 ADT"

require 5;
use strict;
use Test;
BEGIN { plan tests => 25 };
use Text::Shoebox::Lexicon;
use Text::Shoebox::Entry;
ok 1;

#$Text::Shoebox::Debug = 1;

my $temp = 'temp.sf';
my($idem, $other);

sub idem {
  my $x = $_[0] || $other;

  die "What, no idem set?"  unless $idem and ref $idem and $idem->entries_as_lol;
  die "What, no other sie?" unless $x    and ref $x    and $x   ->entries_as_lol;
  my $one = $idem->entries_as_lol;
  my $two = $x   ->entries_as_lol;
  
  return 0 unless @$one == @$two;
  
  my($i,$j,$e1,$e2);
  for($i = 0; $i < @$one; ++$i) {
    $e1 = $one->[$i];
    $e2 = $two->[$i];
    unless( @$e1 == @$e2 ) {
      print "# Diff entry sizes at i=$i: should_", scalar(@$e1),
        " != is_", scalar(@$e2)," \n";
      return 0;
    }
    for($j = 0; $i < @$one; ++$i) {
      unless( $e1->[$j] eq $e2->[$j] ) {
        my ($should, $is) = ($e1->[$j], $e2->[$j]);
        for($should, $is) { s/\n/[NL]/g; }
        print "# Items at i=$i, j=$j differ: should be \"$should\" but is \"$is\" \n";
        return 0;
      }
    }
  }
  return 1;
}

##  $Text::Shoebox::Debug = 2;

print "# Lexicon class tests... Text::Shoebox::Lexicon v$Text::Shoebox::Lexicon::VERSION\n";

$idem = Text::Shoebox::Lexicon->new;
ok ! $idem->entries;
ok $idem->entries_as_lol;
ok scalar @{$idem->entries_as_lol}, 0;
push @{ $idem->entries_as_lol },
 map Text::Shoebox::Entry->new(@$_),
   [ 'foo', 'bar', 'baz', "quux foo\n\t\tchacha", 'thwak', '' ],
   [ 'foo', 'sntrak', 'hoopa heehah', "\n  things um\n  stuff\n"],
;
ok $idem->entries, 2;
ok scalar @{$idem->entries_as_lol}, 2;

#$idem->dump;

if(-e $temp) {
  print "# Unlinking $temp...\n";
  unlink $temp or die "Can't unlink $temp at start!";
}

print "# Writing...\n";
ok $idem->write_file($temp);
sleep 1;
ok -e $temp;
ok -s $temp;

print "# Rereading to compare...\n";
{
  $other = Text::Shoebox::Lexicon->read_file($temp);
  ok scalar($other->entries) == 2;
  # $other->dump; $idem->dump;
}


print "# Rereading to compare...\n";
{
  $other = Text::Shoebox::Lexicon->new;
  $other->no_scrunch(1);
  ok($other != $idem); # sanity
  ok($other->entries_as_lol != $idem->entries_as_lol); # sanity
  $other->read_file($temp);
  # $other->dump; $idem->dump;
  ok idem;
}


print "# Rereading to compare...\n";
{
  $other = Text::Shoebox::Lexicon->new;
  $other->rs($/);
  $other->no_scrunch(1);
  $other->read_file($temp);
  # $other->dump; $idem->dump;
  ok idem;
}


sub read_and_write_given_rs {
  my($rs, $unguessable) = @_;

  $idem->rs($rs);
  ok $idem->write_file($temp);
  sleep 1;

  unless($unguessable) { 
    $other = Text::Shoebox::Lexicon->new;
    $other->no_scrunch(1);
    $other->read_file($temp);
    # $other->dump; $idem->dump;
    unless(idem) {
      print "# No good with guessing RS:\n";
      return;
    }
  }
  
  $other = Text::Shoebox::Lexicon->new;
  $other->rs($rs);
  $other->no_scrunch(1);
  $other->read_file($temp);
  # $other->dump; $idem->dump;

  return 1 if idem;
  print "# No good with explicit RS on reading and writing:\n";
  return 0;
}

print "# Using an RS of \$/... writing...\n";
ok read_and_write_given_rs($/);

print "# Using an RS of \\cm... writing...\n";
ok read_and_write_given_rs("\cm");

print "# Using an RS of \\cj... writing...\n";
ok read_and_write_given_rs("\cj");

print "# Using an RS of \\cm\\cj... writing...\n";
ok read_and_write_given_rs("\cj");

print "# Using an RS of \\xF0.. writing...\n";
ok read_and_write_given_rs("\xF0", 1);


print "# End.\n";
ok 1;
unlink $temp or warn "Can't unlink $temp";


