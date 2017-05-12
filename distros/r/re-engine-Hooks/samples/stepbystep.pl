#!perl

use 5.010;

use strict;
use warnings;

use blib;
use blib 't/re-engine-Hooks-TestDist';

use Term::ReadKey;

die "Usage: $0 regexp string1 string2...\n" unless @ARGV >= 2;
my ($rx, @strings) = @ARGV;

++$|;

my $cb;
BEGIN {
 $cb = sub {
  print "executed $_[0] regnode\n";
  Term::ReadKey::ReadMode(4);
  my $key = Term::ReadKey::ReadKey(0);
  Term::ReadKey::ReadMode(1);
 }
}

{
 use re::engine::Hooks::TestDist 'custom' => $cb;

 $rx = qr/$rx/;
}

for my $str (@strings) {
 print "Matching string \"$str\"\n";

 {
  use re::engine::Hooks::TestDist 'custom';
  $str =~ $rx;
 }
}
