#!perl

use Test::More;
use strict;
use warnings;
BEGIN {
    use_ok( 'Text::Parts' ) || print "Bail out!";
}

open my $fh, '>', 't/data/2048.txt' or die $!;
foreach my $i (1 .. 2048) {
  print $fh $i . "\n";
}
close $fh;
mkdir "t/tmp";
my $s = Text::Parts->new(file => 't/data/2048.txt', no_open => 1);
my @filenames = $s->write_files('t/tmp/xx%d.txt', num => 2048, code => sub {my $f = shift; ok -e $f; unlink $f});
foreach my $file (@filenames) {
  ok ! -e $file;
}
unlink 't/data/2048.txt';

done_testing;
