#!/usr/bin/perl
# -*- CPerl -*-

use strict;
use warnings;

use Getopt::Long;
use Fcntl qw(SEEK_SET SEEK_END);

use IO::Compress::Gzip qw($GzipError);

# This is a simple tool to compress a WARC file record-by-record for
#  testing purposes.  This is *not* a substitute for WARC::Builder.

my $sl_opt = undef;
my $output = undef;
my $want_FEXTRA = 0;

GetOptions ("output|o=s" => \$output,
	    "with-sl:s" => \$sl_opt,
	    "extra-header!" => \$want_FEXTRA);

if (@ARGV < 1) {
  print STDERR "usage: $0 [options] <input file>\n";
  exit 2
}

my $want_sl = defined $sl_opt;
if ($want_sl)
  { die "--with-sl expects either nothing, 'bogus?', 'empty', or 'valid'\n"
      unless $sl_opt =~ m/^(?:|bogus.|empty|valid)$/ }
$sl_opt = 'valid' if $want_sl && $sl_opt eq '';

$output = $ARGV[0].'.gz' unless defined $output;

open IN, '<', $ARGV[0] or die "open input: $!";
open OUT, '>', $output or die "open output: $!";

my @gzopts = (Append => 1, Level => 9, Time => 0, Strict => 1, AutoClose => 0);
if ($want_sl) {
  if ($sl_opt eq 'bogus3')
    { push @gzopts, ExtraField => [[sl => ("\0" x 12)]] }
  elsif ($sl_opt eq 'bogus4')
    { push @gzopts, ExtraField => [[b4 => ("\0" x 12)]] }
  else
    { push @gzopts, ExtraField => [[sl => ("\0" x 8)]] }
} elsif ($want_FEXTRA)
  { push @gzopts, ExtraField => '' }
else
  { push @gzopts, Minimal => 1 }
my $gzout = undef;

my $sl_mark = undef;

sub fill_sl {
  my $full_length = tell $gzout;
  close $gzout;
  if ($want_sl && $sl_opt =~ m/bogus|valid/) {
    my $end_pos = tell OUT;
    $end_pos -= 8 if $sl_opt eq 'bogus2';
    my $buf = pack('VV', $end_pos - $sl_mark, $full_length);
    $buf = "\0\1\2\3\4\5\6\7" if $sl_opt eq 'bogus1';
    seek OUT, $sl_mark + 16, SEEK_SET or die "seek to sl_mark: $!";
    print OUT $buf or die "write sl: $!";
    seek OUT, 0, SEEK_END or die "seek back to end: $!";
  }
  $sl_mark = tell OUT;
}

while (<IN>) {
  if (m/^WARC\/1.0/) {
    if (defined $sl_mark) { fill_sl }
    else { $sl_mark = 0 }
    $gzout = new IO::Compress::Gzip \*OUT, @gzopts;
  }
  print $gzout $_;
}

fill_sl;	# also closes $gzout;
close IN;
close OUT;

exit 0

__END__
