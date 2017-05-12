#!perl

use Test::More;
use strict;
use warnings;
use Test::Requires qw/Digest::MD5/;
BEGIN {
    use_ok( 'Text::Parts' ) || print "Bail out!";
}

open my $fh, '>', 't/data/2048.txt' or die $!;
foreach my $i (1 .. 2048) {
  print $fh $i . "\n";
}
close $fh;
mkdir "t/tmp";

my $s = Text::Parts->new(file => "t/data/2048.txt", no_open => 1);
my $i = 0;
foreach my $p ($s->split(num => 2048)) {
  $p->write_file("t/tmp/x" . ++$i . ".txt");
  my $file = "t/tmp/x" . $i . '.txt';
  ok -f $file, 'file exists';
  my ($all, $all2) = ($p->all, _read_file($file));
  is $file  . " - " . Digest::MD5::md5_hex($all), $file . " - " . Digest::MD5::md5_hex($all2), 'checksum is same' or sleep 2;
}

my @filenames = $s->write_files('t/tmp/xx%d.txt', num => 2048, code => sub {
                                  my $_file = my $file = shift;
                                  $_file =~s{/xx}{/x};
                                  ok -s $_file, 'file exsists';
                                  unlink $file;
                                  unlink $_file;
                                }
                               );
unlink 't/data/2048.txt';

sub _read_file {
  my ($f) = @_;
  local $/;
  open my $fh, '<', $f;
  my $str = <$fh>;
  close $fh;
  return $str;
}

done_testing;
