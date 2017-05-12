#!perl

use strict;
use warnings;

use URI;
use Test::More tests => 14;

use_ok('URI::BNode');

ok('asdf' =~ $URI::BNode::PN_CHARS_BASE, 'PN_CHARS_BASE ok');
ok('asdf-' =~ $URI::BNode::BNODE, 'BNODE ok');
ok('_asdf-' =~ $URI::BNode::BNODE, 'BNODE really ok');
ok('_0-sdf' =~ $URI::BNode::BNODE, 'BNODE genuinely ok');

my $suspect = 'EBLc62CJqdXqdxFLysMkoC';
#$suspect = substr($suspect, 0, 1);

#warn $suspect;

ok($suspect =~ $URI::BNode::BNODE, 'BNODE seriously ok');

my $bnode = URI::BNode->new('_:asdf');

ok($bnode, 'bnode exists');

is($bnode->name, 'asdf', 'bnode opaque matches');

$bnode = URI::BNode->new;

diag($bnode);

my $uuid = $bnode->to_uuid_urn;
isa_ok($uuid, 'URI::urn::uuid', 'uuid derived correctly');
diag($uuid);

my $bnode2 = URI::BNode->from_uuid_urn($uuid);

diag($bnode2);

#my (undef, $x) = split /:/, $bnode2;

#warn $URI::BNode::BNODE;

ok($bnode2 =~ $URI::BNode::BNODE, "$bnode2 matches regex");

isa_ok($bnode2, 'URI::BNode', 'regenerated bnode');

my $bn3 = URI::BNode->new('_:_._');
isa_ok($bn3, 'URI::BNode', 'ugly but valid');

my $base = URI->new('http://perennial-example.com/');

my $skolem = $bnode2->skolemize($base);
my $b2name = $bnode2->name;

ok($skolem->path =~ m!/$b2name$!, 'skolem matches');

my $de_sk = URI::BNode->de_skolemize($skolem);

ok("$bnode2" eq "$de_sk", 'skolemization round-trip');
