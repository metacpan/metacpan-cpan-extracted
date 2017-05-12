#!perl

use Test::More;
use strict;
use warnings;
BEGIN {
    use_ok( 'Text::Parts' ) || print "Bail out!";
}
{
  open my $fh, '>', 't/data/10.txt' or die $!;
  foreach my $i (1 .. 100) {
    print $fh $i . "\n";
  }
  close $fh;

  mkdir "t/tmp";
  foreach my $i (0, 1, 2) {
    my $s = Text::Parts->new(file => 't/data/10.txt', no_open => 1);
    ok $s;
    my @filenames = $s->write_files('t/tmp/xx%d.txt', num => 10, code => sub { ok unlink(shift) }, start_number => $i);
    is scalar @filenames, 10, 'scalar @filenames is 10';
    is $filenames[0]  , sprintf('t/tmp/xx%d.txt', $i), "start number is $i";
    is $filenames[-1] , sprintf('t/tmp/xx%d.txt', $i + 9), "last number is " . ($i + 9);
  }
}
{
  foreach my $i (0, 1, 2) {
    my $s = Text::Parts->new(file => 't/data/10.txt', no_open => 1);
    ok $s;
    my @filenames = $s->write_files('t/tmp/xx%d.txt', num => 10, code => sub { ok unlink(shift) }, start_number => $i, last_number => 4);
    is scalar @filenames, 4 - $i + 1;
    is $filenames[0]  , sprintf('t/tmp/xx%d.txt', $i), "start number is $i";
    is $filenames[-1] , sprintf('t/tmp/xx%d.txt', 4), "last number is " . 4;
  }
}
{
  foreach my $i (1, 2, 3) {
    my $s = Text::Parts->new(file => 't/data/10.txt', no_open => 1);
    ok $s;
    my @filenames = $s->write_files('t/tmp/xx%d.txt', num => 10, code => sub { ok unlink(shift) }, start_number => 0, max_num => $i);
    is scalar @filenames, $i;
    is $filenames[-1] , sprintf('t/tmp/xx%d.txt', $i - 1), "last number is " . ($i - 1);
  }
}
unlink 't/data/10.txt';

done_testing;
