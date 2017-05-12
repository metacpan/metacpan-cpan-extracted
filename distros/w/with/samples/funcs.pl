#!/usr/bin/env perl

use strict;
use warnings;

my $pod = $ARGV[0] || './perlfunc.pod';
open my $p, '<', $pod or die "open($pod): $!";
my $d = do { local $/; <$p> };
my ($f) = $d =~ /=over[^\n]*\n(.*?)=back/s;
die "no functions" unless $f;
my @f = $f =~ /C<([^<>]+)>/g;
my %dup;
@f = sort
      grep { eval { () = prototype "CORE::$_"; 1 } }
       grep !$dup{$_}++, @f;
my $c = 10;
my $base = "my \@core = qw/";
my $out = $base;
my $l = length $base;
my $first = 1;
for (@f) {
 if ($l + (1 - $first) + length() <= 78) {
  if ($first) {
   $first = 0;
  } else {
   $l++;
   $out .= ' ';
  }
  $l += length;
  $out .= $_;
 } else {
  $l = length($base) - 1;
  $out .= "\n" . (' ' x $l);
  redo;
 }
}
$out .= "/;\n";
print $out;
