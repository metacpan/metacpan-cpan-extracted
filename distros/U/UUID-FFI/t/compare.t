use strict;
use warnings;
use Test::More tests => 2;
use UUID::FFI;

my @uuids = map { chomp; UUID::FFI->new($_) } <DATA>;

my @expected = qw(
  1c2ca1de-90a1-491f-b64c-528d39f9b760
  3bf24b65-9229-4ab4-aefe-285641142f6c
  49ca5fcd-2c58-4e0a-ac5f-fa5bebee7473
  5858040f-961b-4dd7-8e9e-c3bc94d29466
  8cfdb933-c1fb-456c-a290-7ae33164793f
  b895fa51-0909-4e73-8eed-1d298b31657d
  d51913db-43b1-4538-a152-3abbeda6daa2
  d84e90b3-000e-4018-8939-2ab14df37da4
  df69982f-41b5-4efd-a9a1-c7c58bfeb5a5
  fca307d8-dca8-490a-a181-aa81ab1ed662
);

is_deeply [map { $_->as_hex } sort { $a->compare($b) } @uuids], \@expected, 'uuid.compare';
is_deeply [map { $_->as_hex } sort { $a <=> $b } @uuids], \@expected, 'uuid cmp';

__DATA__
5858040f-961b-4dd7-8e9e-c3bc94d29466
49ca5fcd-2c58-4e0a-ac5f-fa5bebee7473
df69982f-41b5-4efd-a9a1-c7c58bfeb5a5
8cfdb933-c1fb-456c-a290-7ae33164793f
d51913db-43b1-4538-a152-3abbeda6daa2
d84e90b3-000e-4018-8939-2ab14df37da4
1c2ca1de-90a1-491f-b64c-528d39f9b760
b895fa51-0909-4e73-8eed-1d298b31657d
fca307d8-dca8-490a-a181-aa81ab1ed662
3bf24b65-9229-4ab4-aefe-285641142f6c
