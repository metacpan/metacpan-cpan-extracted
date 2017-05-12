use strict;
use warnings;
use Test::More;

use UUID::Object;
plan skip_all
  => sprintf("Unsupported UUID::Object (%.2f) is installed.",
             $UUID::Object::VERSION)
  if $UUID::Object::VERSION > 0.80;

plan tests => 52;

eval q{ use UUID::Generator::PurePerl::NodeID; };
die if $@;

my $g = UUID::Generator::PurePerl::NodeID->new();

my ($node, $node0, $changed);

$node0 = eval { $g->physical_node_id };
SKIP: {
    skip 'physical_node_id is not supported', 15 if $@ || ! defined $node0;

    for my $i (1 .. 5) {
        $node = $g->physical_node_id;

        is( length($node), 6, "trail ${i}: physical_node_id() is 6 octets" );
        ok( unpack('C1', $node) & 0x80 == 0, "trail ${i}: physical_node_id()" );
        is( $node, $node0, "trail ${i}: MAC address unaltered" );
    }
}

$node0 = $g->pseudo_node_id(0);
for my $i (1 .. 5) {
    $node = $g->pseudo_node_id(0);

    is( length($node), 6, "trail ${i}: pseudo_node_id(0) is 6 octets" );
    ok( unpack('C1', $node) & 0x80, "trail ${i}: pseudo_node_id(0) is multicast MAC" );
    is( $node, $node0, "trail ${i}: pseudo MAC address unaltered" );
}

$changed = 0;
$node0 = $g->pseudo_node_id(1);
for my $i (1 .. 5) {
    $node = $g->pseudo_node_id(1);

    is( length($node), 6, "trail ${i}: pseudo_node_id(1) is 6 octets" );
    ok( unpack('C1', $node) & 0x80, "trail ${i}: pseudo_node_id(1) is multicast MAC" );

    $changed ++ if $node0 ne $node;
}
ok( $changed > 0, "pseudo_node_id(1) changed" );

$changed = 0;
$node0 = $g->random_node_id;
for my $i (1 .. 5) {
    $node = $g->random_node_id;

    is( length($node), 6, "trail ${i}: random_node_id() is 6 octets" );
    ok( unpack('C1', $node) & 0x80, "trail ${i}: random_node_id() is multicast MAC" );

    $changed ++ if $node0 ne $node;
}
ok( $changed > 0, "random_node_id() changed" );

