use Test::More tests => 14;

use warnings;
use strict;

use Tree::Trie;

my $tree = new Tree::Trie;
ok( ($tree->add_data(foo => 1, bar => 2) == 2), 'Basic add data');
ok( ($tree->lookup_data('foo') == 1), 'Basic lookup data');
ok( ($tree->add_data(foo => 3, baz => 4) == 1), 'Add and update data');
ok( ($tree->lookup_data('foo') == 3), 'Lookup updated data');
ok( ($tree->delete_data(qw/foo baz bip/) == 2), 'Delete data');
ok(!($tree->lookup_data('foo')), 'Confirm deletion');

$tree = new Tree::Trie;
ok(
	($tree->add_data(
		foo       => 'oof',
		bar       => 'rab',
		barnstorm => 'mrotsnrab',
	) == 3),
	'Add more data'
);
$tree->deepsearch('choose');
my $test = $tree->lookup_data('ba');
ok( ($test eq 'rab' || $test eq 'mrotsnrab'), 'Choose data lookup' );

$tree = new Tree::Trie;
ok(
	($tree->add_data(
		'/usr/' => '/rsu/',
		'/usr/local/' => '/lacol/rsu/',
		'/var/' => '/rav/',
	) == 3),
	'Even more data added'
);
$tree->deepsearch("prefix");
ok(($tree->lookup_data('/usr/foo.txt') eq '/rsu/'), 'Prefix data lookup' );
ok(($tree->lookup_data('/usr/lo') eq '/rsu/'), 'Another prefix data lookup');
ok(($tree->lookup_data('/usr/local/') eq '/lacol/rsu/'), 'Exact data lookup' );
ok(
	($tree->lookup_data('/usr/local/bar.html') eq '/lacol/rsu/'),
	'Yet another directory data lookup'
);
my @ret = $tree->lookup_data('');
ok((@ret == 6), 'Prefix lookup multiple results');
