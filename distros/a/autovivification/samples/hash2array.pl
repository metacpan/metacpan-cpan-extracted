#!perl

use strict;
use warnings;

use Fatal qw<open close>;
use Text::Balanced qw<extract_bracketed>;

open my $hash_t,       '<', 't/20-hash.t';
open my $array_t,      '>', 't/30-array.t';
open my $array_fast_t, '>', 't/31-array-fast.t';

sub num {
 my ($char) = $_[0] =~ /['"]?([a-z])['"]?/;
 return ord($char) - ord('a')
}

sub hash2array {
 my ($h) = @_;
 return $h unless $h and ref $h eq 'HASH';
 my @array;
 for (keys %$h) {
  $array[num($_)] = hash2array($h->{$_});
 }
 return \@array;
}

sub dump_array {
 my ($a) = @_;

 return 'undef' unless defined $a;

 if (ref $a) {
  die "Invalid argument" unless ref $a eq 'ARRAY';
  return '[ ' . join(', ', map dump_array($_), @$a) . ' ]';
 } else {
  $a = "'\Q$a\E'" if $a !~ /^\s*\d/;
  return $a;
 }
}

sub extract ($$) {
 extract_bracketed $_[0], $_[1],  qr/.*?(?<![\\@%])(?:\\\\)*(?=$_[1])/
}

sub convert_testcase ($$) {
 local $_ = $_[0];
 my $fast = $_[1];

 s!(\ba\b)?(\s*)HASH\b!($1 ? 'an': '') . "$2ARRAY"!eg;
 s{
  [\{\[]\s*(['"]?[a-z]['"]?(?:\s*,\s*['"]?[a-z]['"]?)*)\s*[\}\]]
 }{
  '[' . join(', ', map { my $n = num($_); $fast ? $n : "\$N[$n]" }
                    split /\s*,\s*/, $1) . ']'
 }gex;
 s!%(\{?)\$!\@$1\$!g;

 my $buf;
 my $suffix = $_;
 my ($bracket, $prefix);
 while (do { ($bracket, $suffix, $prefix) = extract($suffix, '{'); $bracket }) {
  my $array = dump_array(hash2array(eval $bracket));
  $buf .= $prefix . $array;
 }
 $buf .= $suffix;
 $buf =~ s/\s+/ /g;
 $buf =~ s/\s+$//;

 return "$buf\n";
}

my $in_data;
while (<$hash_t>) {
 if (/^__DATA__$/) {
  $in_data = 1;
  print $array_t      $_;
  print $array_fast_t $_;
 } elsif (!$in_data) {
  s{'%'}{'\@'};
  print $array_t      $_;
  print $array_fast_t $_;
 } else {
  print $array_t      convert_testcase($_, 0);
  print $array_fast_t convert_testcase($_, 1);
 }
}

close $hash_t;
close $array_t;
close $array_fast_t;

open my $hash_kv_t,  '<', 't/22-hash-kv.t';
open my $array_kv_t, '>', 't/32-array-kv.t';

$in_data = 0;
while (<$hash_kv_t>) {
 if (/^__DATA__$/) {
  $in_data = 1;
 } elsif (!$in_data) {
  s{'%'}{'\@'};
  if (/\bplan\s*[\s\(]\s*tests\b/) {
   s/\s*;?\s*$//;
   s/^(\s*)//;
   $_ = qq($1if ("\$]" >= 5.011) { $_ } else { plan skip_all => 'perl 5.11 required for keys/values \@array' }\n);
  }
 } else {
  $_ = convert_testcase($_, 1);
 }
 print $array_kv_t $_;
}
