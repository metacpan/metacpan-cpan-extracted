#!/usr/bin/perl -wn
$idx=$1 if /<keyMap\s+index=\"(\d+)\">/; 
$out[$1][$idx]=$2 if /<key\s+code=\"(\d+)\"\s+output=\"(.+)\"\/>/;

#use strict;

sub fmt($) {
  my $in = shift; 
  return q(--) unless defined $in; 
  $in =~ s/&#x00([2-7].);/ chr hex $1 /e; 
  $in =~ s/&#x00(..);/\\x$1/; 
  $in
} 

sub fmta($) {
  my $in = shift; 
  map fmt($_), @$in
}

sub fmt_c {
  my $in = shift; 
  my $mid = ($in =~ /^\p{NonspacingMark}/ ? ' ' : '');
  $mid .= "\x{203c}" if length $in > 1 and $in ne '--';		# ‼
  return qq($mid$in);
}

END { 
  for (0..$#out) {
    my @o = fmta $out[$_]; 
    my $c = $o[0] || 0; 
    my $n=$seen{$c}++ || q(); 
    $x{qq($c$n)} = [@o[3..$#o]]
  }
  for my $row (q(`1234567890-=), q(qwertyuiop[]\\), q(asdfghjkl;'), q(zxcvbnm,./)) {
    for (split //, $row) {
      my @o = @{$x{$_}||[]};
      ( my $a = fmt_c($o[0]) . fmt_c($o[1]) ) =~ s/(?!^)--//;
      print qq(\t$a), (@o > 2 ? qq(/) : ''), map fmt_c($_), @o[2..$#o];
    }
    print "\n";
  }
}
