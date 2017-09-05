use Test2::V0 -no_srand => 1;
use UUID::FFI;

subtest 'basic' => sub {

  my $uuid = UUID::FFI->new_random;
  isa_ok $uuid, 'UUID::FFI';

};

subtest 'as_string' => sub {

  my $uuid = UUID::FFI->new_random;
  like $uuid->as_hex, qr{^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$}, 'uuid.as_hex';
  note $uuid->as_hex;
};

subtest 'clone' => sub {

  my $uuid = UUID::FFI->new('267a6045-e470-49fc-b9c8-9e20d39892e0');
  isa_ok $uuid, 'UUID::FFI';

  my $clone = $uuid->clone;
  isnt $$clone, $$uuid, 'Different actual objects';
  is $clone->as_hex, $uuid->as_hex, 'as string matches';
  is $uuid->compare($clone), 0, 'compare';

};

subtest 'is_null' => sub {

  is(UUID::FFI->new_null->is_null, T(), 'is_null ~> true ');
  is(UUID::FFI->new_random->is_null, F(), 'is_null ~> false');

};

subtest 'new' => sub {

  my $uuid = UUID::FFI->new('267a6045-e470-49fc-b9c8-9e20d39892e0');
  isa_ok $uuid, 'UUID::FFI';

  is $uuid->as_hex, '267a6045-e470-49fc-b9c8-9e20d39892e0', 'uuid.as_hex';
  note $uuid->as_hex;

  eval { UUID::FFI->new('foo') };
  isnt $@, '', 'bad hex';
  note $@;
};

subtest 'new_null' => sub {

  my $uuid = UUID::FFI->new_null;
  isa_ok $uuid, 'UUID::FFI';

  is $uuid->as_hex, '00000000-0000-0000-0000-000000000000', 'uuid.as_hex';
  note $uuid->as_hex;

  ok $uuid->is_null, 'is_null';
};

subtest 'new_random' => sub {

  my $uuid = UUID::FFI->new_random;
  isa_ok $uuid, 'UUID::FFI';

  like $uuid->as_hex, qr{^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$}, 'uuid.as_hex';
  note $uuid->as_hex;

  is $uuid->type, 'random', 'uuid.type';
};

subtest 'new_time' => sub {

  my $uuid = UUID::FFI->new_time;
  isa_ok $uuid, 'UUID::FFI';

  like $uuid->as_hex, qr{^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$}, 'uuid.as_hex';
  note $uuid->as_hex;

  is $uuid->type, 'time', 'uuid.type';
};

subtest 'stringify' => sub {

  my $uuid = UUID::FFI->new_random;
  isa_ok $uuid, 'UUID::FFI';

  is "$uuid", $uuid->as_hex, 'stringify';
  note $uuid->as_hex;

};

subtest 'time' => sub {

  my $uuid = UUID::FFI->new('cf74dba4-64a5-11e4-9128-002522dfb514');
  is $uuid->time, 1415162404, 'uuid.time';

};

subtest 'type' => sub {

  is(UUID::FFI->new_random->type, 'random', 'type = random');
  is(UUID::FFI->new_time->type,   'time', 'type = time');

};

subtest 'variant' => sub {

  my $uuid = UUID::FFI->new_random;
  like $uuid->variant, qr{^(ncs|dce|microsoft|other)$}, 'variant';
  note $uuid->variant;

};

subtest 'compare' => sub {

  my @uuids = map { UUID::FFI->new($_) } qw(
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
  );

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

  is [map { $_->as_hex } sort { $a->compare($b) } @uuids], \@expected, 'uuid.compare';
  is [map { $_->as_hex } sort { $a <=> $b } @uuids], \@expected, 'uuid cmp';

};

done_testing;

