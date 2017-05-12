#!/usr/bin/perl

use Test::More;
use Text::Parts;
use strict;
BEGIN {
  eval {require 5.8.0;};
  eval "use Test::More skip_all => q{$@}" if $@;
}

my $p = Text::Parts->new();

my @test =
  (
   {
    t => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\naaaaaaaaaaaaaaaa\n111",
    seek => 5,
   },
   {
    #     123456789012345678901234567890
    t => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\naaaaaaaaaaaaaaaa\n111",
    seek => 33,
   },
   {
    #     123456789012345678901234567890123
    t => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\naaaaaaaaaaaaaaaa\n111",
    seek => 35,
   },
   {
    #     123456789012345678901234567890123
    t => join("\n", map {$_ x 600} ('a' .. 'c')),
    seek => 1000,
   },
  );

my @answer =
  (
   "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n",
   "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n",
   "aaaaaaaaaaaaaaaa\n",
   ("b" x 600 . "\n"),
  );


for my $i (0 .. $#test) {
  my $txt = $test[$i]->{t};
  open my $fh, '<', \$txt or die $!;
  seek $fh, $test[$i]->{seek}, 0;
  $p->_move_line_start($fh);
  is scalar <$fh>, $answer[$i], "test $i";
}

done_testing;
