use Test::More tests => 9;

use warnings;
use strict;

use Tree::Trie;

my $tree = new Tree::Trie;
ok(
	($tree->add(
		[qw/00 01 02 03/], [qw/00 01 05 06/], "0001", [qw/aa bb cc ddd/]
	) == 4),
	'Insert arrayrefs'
);
$tree->deepsearch("boolean");
ok(
	(scalar $tree->lookup(["00"])),
	'Boolean lookup for arrayref present prefix'
);
ok(
	!(scalar $tree->lookup(["000"])),
	'Boolean lookup for arrayref missing prefix'
);
ok((scalar $tree->lookup("000")), 'Boolean lookup for present prefix');

$tree->deepsearch("count");
ok(
	($tree->lookup([qw/00 01 02/]) == 1),
	'Count lookup arrayref present prefix'
);
ok(($tree->lookup(["00"]) == 2), 'Count lookup arrayref present prefix - > 1');
ok(($tree->lookup("00") == 1), 'Count lookup present prefix');
ok(
	(scalar $tree->remove("0001", [qw/aa bb cc ddd/]) == 2),
	'Remove arrayref and normal keys'
);
ok(($tree->lookup([]) == 2), 'Confirm removal');
