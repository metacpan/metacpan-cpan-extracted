use Test::More tests => 57;

use warnings;
use strict;

BEGIN { use_ok('Tree::Trie'); }

# Basic tests -- adding, lookup and deepsearch params
my $tree = new Tree::Trie;
ok(
	($tree->add(qw/foo foot bar barnstorm food happy fish ripple/) == 8),
	'Basic Add'
);

# Boolean lookups just return truth value
ok( ($tree->deepsearch("boolean") == 0), 'Set boolean deepsearch' );
ok( (scalar $tree->lookup("f")), 'Found present prefix' );
ok(!(scalar $tree->lookup("x")), 'Did not find missing prefix' );

# Choose just randomly chooses one word to return
ok( ($tree->deepsearch("choose") == 1), 'Set choose deepsearch' );
my $test = $tree->lookup("ba");
ok( ($test eq 'bar' || $test eq 'barnstorm'), 'Choose by present prefix' );
ok(!(defined($tree->lookup("q"))), 'Did not find missing prefix' );

# Count counts the number of words
ok(($tree->deepsearch("count") == 2), 'Set count deepsearch');
ok(($tree->lookup("fo") == 3), 'Correct count for present prefix');
ok(($tree->lookup("m") == 0), 'Zero count for missing prefix');

# Test list context lookup  (poorly)
my @test = $tree->lookup("");
ok(($#test == 7), 'List context lookup');

# Testing removal
ok(
	($tree->remove(qw/foo ripple/) == 2 && $tree->lookup("") == 6),
	'Remove operates properly'
);

# Exact only returns if the exact entry exists
$tree = new Tree::Trie;
$tree->add_data('foo', 'oof');
$tree->add_data('foot', 'toof');
$tree->add_data('bar', 'rab');
$tree->deepsearch('exact');
ok(!defined($tree->lookup('fo')), 'Non-exact lookup fails');
ok( 'foo' eq $tree->lookup('foo'), 'Exact lookup succeeds');
ok(!defined($tree->lookup_data('b')), 'Non-exact data lookup fails');
ok( 'oof' eq $tree->lookup_data('foo'), 'Exact data lookup succeeds');


# Testing longest prefix lookup
$tree = new Tree::Trie;
ok(($tree->add(qw#/usr/ /usr/local/ /var/#) == 3), 'Adding more data');
$tree->deepsearch("prefix");
ok(($tree->lookup('/usr/foo.txt') eq '/usr/'), 'Prefix lookup');
ok(
	($tree->lookup('/usr/lo') eq '/usr/'),
	'Potentially ambiguous prefix lookup'
);
ok(($tree->lookup('/usr/local/') eq '/usr/local/'), 'Exact prefix lookup');
ok(
	($tree->lookup('/usr/local/bar.html') eq '/usr/local/'),
	'Another prefix lookup'
);

# Testing suffix lookup
$tree = new Tree::Trie;
ok(
	($tree->add(
		qw/foo foot bar barnstorm food happy fish ripple fission/
	) == 9),
	'Adding data again'
);
ok(($tree->deepsearch("choose") == 1), 'Set deepsearch to choose, again');
$test = $tree->lookup("ba", 2);
ok(($test eq 'r' || $test eq 'rn'), 'Suffix lookup');
$test = $tree->lookup("fis", -1);
ok(($test eq 'h' || $test eq 'sion'), 'Unbounded suffix lookup');
ok(($tree->lookup("barn", -1) eq 'storm'), 'More unbounded suffix lookup');

ok(($tree->deepsearch("count") == 2), 'Set deepsearch to count for suffix');
ok(($tree->lookup("f", 2) == 2), 'Multiple non-unique suffixes');
ok(($tree->lookup("f", 3) == 5), 'Multiple unique suffixes');
ok(($tree->lookup("m", 1) == 0), 'Missing prefix lookup');
ok(($tree->lookup("", 1) == 4), 'Count of unqiue prefix letters');
ok(
	($tree->lookup("", -1) == 9),
	'Foolishly using suffix to count words in trie'
);
@test = $tree->lookup("ba", 3);
ok((scalar @test == 2), 'Suffix lookup in list context');

# Testing mutiple add
$tree = new Tree::Trie;
ok(($tree->add(qw/foo bar baz/) == 3), 'Adding multiple entries');
ok(($tree->add(qw/foo bar quux/) == 1), 'Adding existing entries');

# Test end marker modification
$tree = new Tree::Trie({
	end_marker        => 'xx',
	freeze_end_marker => 'yup',
});
ok( ($tree->{_END} eq 'xx'), 'Verify explicit end marker');
ok( $tree->{_FREEZE_END}, 'Verify marker is frozen');
ok(!$tree->freeze_end_marker(undef), 'Unfreezing end marker');
ok(!$tree->{_FREEZE_END}, 'Verify marker is unfrozen');
ok( ($tree->end_marker('ll') eq 'll'), 'Setting end marker' );
ok( ($tree->{_END} eq 'll'), 'Verify end marker');
ok( ($tree->add(qw/llama llewllen loft/) == 3), 'Add some data');
ok( ($tree->{_END} eq 'll'), 'Verify end marker did not change');
ok(
	($tree->add(
		[qw/aa bb cc ll/],
		[qw/00 77 88/],
		'llama',
		[qw/hh ll hu jo gh/],
	) == 3),
	'Add some data which will change end marker'
);
ok( ($tree->{_END} ne 'll'), 'Verify end marker changed');
@test = $tree->lookup('');
ok( (scalar @test == 6), 'Verify things still work');

# Testing total deletion
$tree = new Tree::Trie;
$tree->add('foo');
ok( ($tree->remove('foo') == 1), 'Remove only datum');
@test = $tree->lookup('');
ok( (scalar @test == 0), 'Verify trie still works');


# Test to tickle a cute bug (now fixed) found by Stefan Buehler. I quote:
# $trie->lookup("") fails for the "choose" deepsearch in scalar context
# if the trie is empty (endless loop)
$tree = new Tree::Trie;
$tree->deepsearch('choose');
ok( '' eq $tree->lookup(''), 'Verify infinite loop bug with empty trie');

# Testing add_all

# First we test the simple case, two tries with the same end marker.
$tree = new Tree::Trie;
$tree->add(qw/fish fulminate porphyry porpoise/);
my $tree2 = new Tree::Trie;
$tree2->add(qw/kalamata fish aniline fullness/);
$tree->add_all($tree2);

@test = $tree->lookup('');
ok((7 == scalar @test), 'Verify new trie has all entries');

@test = sort $tree->lookup('ful');
ok((2 == scalar @test), 'Verify lookup succeeds');
ok(('fulminate' eq $test[1]), 'Verify entry from first trie exists');
ok(('fullness' eq $test[0]), 'Verify entry from second trie exists');

# Now we'll make sure things work when the end markers differ.
$tree = new Tree::Trie;
$tree->add(qw/aab baa aca bca/);
$tree2 = new Tree::Trie;
$tree2->add(
	'aac', ['a', '', 'b'], ['ll', 'a', '']
);
$tree->add_all($tree2);

ok( '' ne $tree->{_END}, 'New trie has new end marker');

@test = $tree->lookup('');
ok( 7 == scalar @test, 'Lookup still works after add_all');
@test = $tree->lookup('aa');
ok( 2 == scalar @test, 'Prefix lookup still works');
