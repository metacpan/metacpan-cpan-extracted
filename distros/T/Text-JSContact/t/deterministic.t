#!/usr/bin/perl

# Writing the same Card gives the same bytes, in every process: a CardDAV
# server gives every distinct body a new ETag, and a client that sees one
# refetches the card.  Perl orders hashes differently in every process
# (PERL_HASH_SEED), so the writes are compared across processes too.

use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha1_hex);
use Encode qw(encode_utf8);

use lib 'lib';
use Text::JSContact qw(vcard_to_jscontact jscontact_to_vcard);

my $DIR = 't/data/vcard';
my @files = sort glob "$DIR/*.vcf";

# one digest per file, written by this process
sub digests {
  my %d;
  for my $file (@files) {
    open my $fh, '<:raw', $file or die "$file: $!";
    my $raw = do { local $/; <$fh> };
    $d{$file} = sha1_hex(encode_utf8(jscontact_to_vcard(vcard_to_jscontact($raw))));
  }
  return \%d;
}

if (@ARGV && $ARGV[0] eq '--digests') {
  my $d = digests();
  print "$_ $d->{$_}\n" for sort keys %$d;
  exit 0;
}

ok(@files, 'corpus found');
my $here = digests();

# many writes in one process
for my $file (@files) {
  open my $fh, '<:raw', $file or die "$file: $!";
  my $card = vcard_to_jscontact(do { local $/; <$fh> });
  my %seen;
  $seen{jscontact_to_vcard($card)}++ for 1..20;
  is(scalar keys %seen, 1, "$file: twenty writes, one result");
}

# and in processes with different hash seeds
for my $seed (1, 2, 3, 42, 12345) {
  local $ENV{PERL_HASH_SEED} = $seed;
  local $ENV{PERL_PERTURB_KEYS} = 2;
  my @out = `$^X -Ilib $0 --digests`;
  my %there = map { chomp; split / / } @out;
  is_deeply(\%there, $here, "PERL_HASH_SEED=$seed: the same bytes");
}

done_testing;
