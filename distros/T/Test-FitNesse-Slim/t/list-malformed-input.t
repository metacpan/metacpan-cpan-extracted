#! perl

use strict;
use utf8;
use warnings;
use Encode qw(encode);
use lib 'lib';
use Test::More;
use Test::FitNesse::Slim::List;

sub dies_like {
  my($wire,$pattern,$name,$limits) = @_;
  my $ok = eval { Test::FitNesse::Slim::List->new($wire, limits => ($limits || {}))->list; 1 };
  ok(!$ok && $@ =~ $pattern, $name);
}

sub utf16_length {
  my($s) = @_;
  return length(encode('UTF-16BE',$s)) / 2;
}

sub encoded_item {
  my($s,$length) = @_;
  $length = utf16_length($s) unless defined $length;
  return sprintf('%06d:%s:',$length,$s);
}

my $round = [ 'ASCII', 'München', 'Tartu õun', 'Mae govannen, mellon nín',
  'é', '漢', '😀', "e\x{301}", 'x😀y' ];
my $wire = Test::FitNesse::Slim::List->new($round)->serialize;
my @decoded = Test::FitNesse::Slim::List->new(encode('UTF-8',$wire))->list;
is_deeply(\@decoded,$round,'strict UTF-8 round trip preserves BMP, supplementary, and combining text');

my $literal = '[not a serialized list]';
my @literal = Test::FitNesse::Slim::List->new(Test::FitNesse::Slim::List->new([$literal])->serialize)->list;
is_deeply(\@literal,[$literal],'malformed bracket-prefixed child remains a literal string like FitNesse');
my @delimiters = Test::FitNesse::Slim::List->new(
  Test::FitNesse::Slim::List->new(['[',']',':','text:[inside]'])->serialize
)->list;
is_deeply(\@delimiters,['[',']',':','text:[inside]'],
  'delimiters inside ordinary string values do not affect list structure');

my $invalid_utf8 = encode('UTF-8','[000001:000001:x:]');
substr($invalid_utf8,-3,1,"\xff");
dies_like($invalid_utf8,qr/non-UTF-8/,'rejects invalid UTF-8');
my $truncated_utf8 = '[000001:000001:x:]';
substr($truncated_utf8,index($truncated_utf8,'x'),1,pack('C',0xc3));
dies_like($truncated_utf8,qr/non-UTF-8/,'rejects an incomplete multibyte UTF-8 sequence');

dies_like('[000001:000001:😀:]' ,qr/available UTF-16/,
  'rejects a declared UTF-16 length that splits a supplementary character');
dies_like('[000001:000004:abc:]' ,qr/item is not terminated/,
  'rejects an item length that consumes its separator');
dies_like('[000001:000001:x:]]',qr/trailing serialized data/,
  'rejects trailing bytes after the list close');
dies_like('[00000x:]',qr/missing list-length/,'rejects a nonnumeric list count');
dies_like('[999999999999999999999999:]',qr/configured maximum/,
  'rejects an overflowing count before numeric conversion');
dies_like('[000000:unfinished',qr/missing close bracket/,'rejects a missing closing delimiter');
dies_like('[000001:000001:x]',qr/item is not terminated/,'rejects a missing item separator');

my $nested = Test::FitNesse::Slim::List->new([ [ [ 'deep' ] ] ])->serialize;
dies_like($nested,qr/nested-list depth/,'enforces the configured nesting limit',
  { nesting => 2 });
my $two_items = Test::FitNesse::Slim::List->new([qw(a b)])->serialize;
dies_like($two_items,qr/configured maximum/,'enforces the total element limit',
  { elements => 1 });
my $long_item = Test::FitNesse::Slim::List->new(['abcd'])->serialize;
dies_like($long_item,qr/configured maximum/,'enforces the item length limit',
  { item_units => 3 });
my $oversized_wire = Test::FitNesse::Slim::List->new(['abcd'])->serialize;
dies_like($oversized_wire,qr/frame exceeds/,'enforces the serialized frame limit',
  { frame_bytes => 8 });

# The outer grammar requires a list even though zero-length strings are valid list items.
dies_like('000000:',qr/missing open bracket/,'rejects a non-list payload');
my @empties = Test::FitNesse::Slim::List->new(Test::FitNesse::Slim::List->new(['',undef,'0'])->serialize)->list;
is_deeply(\@empties,['','null','0'],'preserves empty, null token, and numeric-zero text');

done_testing;
