use strict;
use utf8;

use Test::More qw(no_plan);
use Test::Exception;

use Encode;

use Unicode::Truncate;


open(my $fh, '<:encoding(utf-8)', 'unidata/GraphemeBreakTest.txt')
  || die "unable to open unicode test data file unidata/GraphemeBreakTest.txt";

while(<$fh>) {
  next if /^#/;

  next if /<surrogate-/; ## skip surrogate tests for now

  chomp;

  /^(.*?)#/ || die "bad line format";
  my ($spec, $desc) = ($1, $_);

  $spec =~ /^\s*÷/ || die "expected start to be breakable ($spec)";
  $spec =~ /÷\s*$/ || die "expected end to be breakable ($spec)";

  $spec =~ s/^\s*÷//;

  my @segs;
  my $curr = '';

  while ($spec =~ /^\s*([0-9A-F]+)\s*(÷|×)/) {
    $curr .= chr(hex($1));
    if ($2 eq '÷') {
      push @segs, $curr;
      $curr = '';
    }
    $spec =~ s/^.*?[÷×]//;
  }

  push @segs, $curr if length($curr);

  my $full = join '', @segs;

  my @ok_lengths = (0);
  my $total_length = 0;

  for my $s (@segs) {
    my $len = length(encode('UTF-8', $s));
    $total_length += $len;
    push @ok_lengths, $total_length;
  }

  my $failed;

  for my $i (0 .. $total_length) {
    my $full_copy = "" . $full;
    my $truncated = truncate_egc($full_copy, $i, '');

    my $truncated_length = length(encode('UTF-8', $truncated));

    if (!grep { $_ == $truncated_length } @ok_lengths) {
      $failed = 1;
      last;
    }
  }

  ok(!$failed, $desc);
}
