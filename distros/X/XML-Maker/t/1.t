#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('XML::Maker') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $root = new XML::Maker("root");
is ($root->count_children(), 0, 'create root node');

my $person = $root->subtag("person", name => 'Vadim');
is ($root->count_children(), 1, 'create child node');

my $info = $person->subtag("info");
is ($person->count_children(), 1, 'create another node');

eval { $person->text("Perl programmer"); };
like($@, qr/^text and subtag\/attach are mutually exclusive/i, 'text and subtags are exclusive');

my $tag = new XML::Maker("test");
$info->attach( $tag );
is($info->count_children(), 1, 'attach tag');

$info->detach( $tag );
is($info->count_children(), 0, 'detach tag');

foo ( $info );
is($info->count_children(), 1, 'add tag in function');

my $out = $root->make();

ok(length($out) > 0, 'make');

sub foo {
	my $obj = shift;
	my $tag = new XML::Maker("foo", 'bar' => 'baz');
	$obj->attach( $tag );
}
