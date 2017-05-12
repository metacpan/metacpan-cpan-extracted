#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use blib;
use jsFind;

BEGIN { use_ok('jsFind'); }

my $t = new jsFind B => 4;

my $i = 0;
foreach my $k (qw{
minima ut dolorem sapiente voluptatemMaiores enim officiis qui veniam ducimus dolores. Voluptas facilis culpa rerum velit quaerat magni omnis.Placeat quia omnis non veritatis autem qui quasi reprehenderit. Et hic fugit et. Sunt voluptates nostrum et distinctio architecto quas.

Vel hic delectus velit occaecati modi possimus. Iste quis repellendus sequi. Ut voluptatem sed expedita ipsum ut delectus. Ab aspernatur animi corrupti excepturi earum odio. Incidunt repellat reprehenderit labore quisquam corrupti sapiente et cumque. Quia id quod et dolor aut expedita atque porro.

Porro porro veritatis enim consectetur. Veniam doloremque culpa nobis assumenda corporis. Corporis ducimus sed sint. Quod quo repellat earum.
}) {
	$t->B_search(Key => $k,
     		Data => { "path" => {
				t => "word $k",
				f => $i },
			},
		Insert => 1,
		Append => 1,
	);
	$i++;
}

if (open(T,"| sort > tree.txt")) {
	print T $t->to_string;
	diag "tree saved in tree.txt";
	close(T);
}

my $tree_size = 0;
open(T, "tree.txt") || die "can't open tree.txt: $!";
while(<T>) {
	$tree_size++;
}

cmp_ok($tree_size, '==', 85, "insert $tree_size/$i");

if (open(T,"> tree.dot")) {
	print T $t->to_dot;
	diag "Graphviz tree saved in tree.dot";
	close(T);
}

my $r = $t->B_search(Key => "velit",
	Data => { "path" => {
			t => "new velit",
			f => 99 }
		},
	Replace => 1,
);

cmp_ok(keys %{$r}, '==', 1, "replace");

$t->to_jsfind(dir=>'./html/lorem');
