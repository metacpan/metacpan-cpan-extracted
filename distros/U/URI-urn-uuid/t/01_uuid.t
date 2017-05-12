use strict;
use URI;
use URI::urn::uuid;
use Test::More 'no_plan';

my $uri = URI->new("urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6");
isa_ok $uri, 'URI::urn::uuid';
is $uri->uuid, "f81d4fae-7dec-11d0-a765-00a0c91e6bf6";

ok $uri->uuid("f81d4fae-7dec-11d0-a765-00a0c91e6baa");
is $uri->uuid, "f81d4fae-7dec-11d0-a765-00a0c91e6baa", "set ok";

ok $uri->uuid_binary;

$uri = URI->new("urn:uuid:xxx");
isa_ok $uri, 'URI::urn::uuid';
is $uri->uuid, undef, "invalid uuid format - undef";
is $uri->uuid_binary, undef, "invalid uuid format - undef";

$uri = URI->new("urn:uuid:");
$uri->uuid("f81d4fae-7dec-11d0-a765-00a0c91e6bf6");
is $uri->uuid, "f81d4fae-7dec-11d0-a765-00a0c91e6bf6";

