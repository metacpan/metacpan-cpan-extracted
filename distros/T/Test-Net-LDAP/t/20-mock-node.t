#!perl -T
use strict;
use warnings;

use Test::More tests => 25;

use Test::Net::LDAP::Mock::Node;

ok my $root = Test::Net::LDAP::Mock::Node->new;

is($root->get_node({dc => 'com'}), undef);
ok my $com = $root->make_node({dc => 'com'});
cmp_ok($root->get_node({dc => 'com'}), '==', $com);
cmp_ok($root->get_node([{dc => 'com'}]), '==', $com);
cmp_ok($root->get_node('dc=com'), '==', $com);

is($com->get_node({dc => 'example'}), undef);
ok my $example = $com->make_node({dc => 'example'});
cmp_ok($com->get_node({dc => 'example'}), '==', $example);
cmp_ok($root->get_node([{dc => 'example'}, {dc => 'com'}]), '==', $example);
cmp_ok($root->get_node('dc=example, dc=com'), '==', $example);

ok my $example2 = $com->make_node('dc=example');
cmp_ok($example, '==', $example2);
cmp_ok($com->get_node('dc=example'), '==', $example2);
cmp_ok($root->get_node('dc=example, dc=com'), '==', $example2);

ok my $foobar = $root->make_node('cn=foo+uid=bar, dc=example, dc=com');
cmp_ok($example->get_node({cn => 'foo', uid => 'bar'}), '==', $foobar);
cmp_ok($root->get_node([{cn => 'foo', uid => 'bar'}, {dc => 'example'}, {dc => 'com'}]), '==', $foobar);
cmp_ok($root->get_node('cn=foo+uid=bar, dc=example, dc=com'), '==', $foobar);
cmp_ok($root->get_node('uid=bar+cn=foo, dc=example, dc=com'), '==', $foobar);
is($root->get_node('cn=foo, dc=example, dc=com'), undef);
is($root->get_node('uid=bar, dc=example, dc=com'), undef);

# DN is case-insensitive
ok my $example3 = $com->make_node('DC=Example');
cmp_ok($example, '==', $example3);
cmp_ok($root->get_node('Dc=EXAMPLE,dC=Com'), '==', $example);
