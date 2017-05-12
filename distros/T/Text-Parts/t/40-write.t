#!perl

use Test::More;
use strict;
use warnings;
use Test::Requires qw/Digest::MD5/;
BEGIN {
    use_ok( 'Text::Parts' ) || print "Bail out!";
}

my %test = (
              1 => [4,
                    [1, 2],
                    [3, 4],
                    [5, 6],
                    [7, 8],
                   ],
              2 => [4,
                    [1111, 2],
                    ['', 4444, 5333],
                    ['', 7888],
                    [8000],
                   ],
              3 => [4,
                    ['aaaaaaaaaaaaaaaaaaaa'],
                    [2222],
                    [3333],
                    [4444],
                   ],
              4 => [3,
                    [1111, 'bbbbbbbbbbbbbbbbbbbb'],
                    [3333],
                    [4444],
                   ],
             );

mkdir "t/tmp";
foreach my $check (0, 1) {
  foreach my $n (sort {$a <=> $b} keys %test) {
    my $split = shift @{$test{$n}};
    my $s = Text::Parts->new(file => "t/data/$n.txt", check_line_start => $check, $^O =~m{MSWin} ? (eol => "\012") : ());
    my $i = 0;
    foreach my $p ($s->split(num => $split)) {
      $p->write_file("t/tmp/x" . ++$i . ".txt");
      my $file = "t/tmp/x" . $i . '.txt';
      ok -f $file, 'file exists';
      is $p->all, _read_file($file), "file contents is ok";
    }
    my @filenames = $s->write_files('t/tmp/xx%d.txt', num => $split);
    foreach my $file (@filenames) {
      my $_file = $file;
      $_file =~s{/xx}{/x};
      ok -s $_file, 'file exsists';
      is Digest::MD5::md5_hex(_read_file($_file)), Digest::MD5::md5_hex(_read_file($file)), 'checksum is same';
      is -s $_file, -s $file, 'file size is same';
      unlink $file;
      unlink $_file;
    }
  }
}

sub _read_file {
  my ($f) = @_;
  local $/;
  open my $fh, '<', $f;
  binmode $fh if $^O =~ m{MSWin};
  my $str = <$fh>;
  close $fh;
  return $str;
}

done_testing;
