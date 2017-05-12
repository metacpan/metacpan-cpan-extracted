use Test::More tests => 37;
use strict;
use warnings;
use Data::Dumper;

use_ok( 'Tree::RB' );

diag( "Testing Tree::RB $Tree::RB::VERSION" );

foreach my $m (qw[
    new
    put 
    iter
    rev_iter
    size
  ])
{
    can_ok('Tree::RB', $m);
}

my $tree = Tree::RB->new;
isa_ok($tree, 'Tree::RB');
ok($tree->size == 0, 'New tree has size zero');

$tree->put('France'  => 'Paris');
$tree->put('England' => 'London');
$tree->put('Hungary' => 'Budapest');
$tree->put('Ireland' => 'Dublin');
$tree->put('Egypt'   => 'Cairo');
$tree->put('Germany' => 'Berlin');

ok($tree->size == 6, 'size check after inserts');
is($tree->min->key, 'Egypt', 'min');
is($tree->max->key, 'Ireland', 'max');

# Iterator tests
my $it;
$it = $tree->iter;
isa_ok($it, 'Tree::RB::Iterator');
can_ok($it, 'next');

my @iter_tests = (
    sub {
        my $node = $_[0]->next;
        ok($node->key eq 'Egypt' && $node->val eq 'Cairo', 'iterator check');
    },
    sub {
        my $node = $_[0]->next;
        ok($node->key eq 'England' && $node->val eq 'London', 'iterator check');
    },
    sub {
        my $node = $_[0]->next;
        ok($node->key eq 'France' && $node->val eq 'Paris', 'iterator check');
    },
    sub {
        my $node = $_[0]->next;
        ok($node->key eq 'Germany' && $node->val eq 'Berlin', 'iterator check');
    },
    sub {
        my $node = $_[0]->next;
        ok($node->key eq 'Hungary' && $node->val eq 'Budapest', 'iterator check');
    },
    sub {
        my $node = $_[0]->next;
        ok($node->key eq 'Ireland' && $node->val eq 'Dublin', 'iterator check');
    },
    sub {
        my $node = $_[0]->next;
        ok(!defined $node, 'iterator check - no more items');
    },
);
foreach my $t (@iter_tests) {
    $t->($it);
}

# Reverse iterator tests
$it = $tree->rev_iter;
isa_ok($it, 'Tree::RB::Iterator');
can_ok($it, 'next');

my @rev_iter_tests = (reverse(@iter_tests[0 .. $#iter_tests-1]), $iter_tests[-1]);

=pod

Longer way to reverse

    my @rev_iter_tests = @iter_tests;
    @rev_iter_tests = (pop @rev_iter_tests, @rev_iter_tests);
    @rev_iter_tests = reverse @rev_iter_tests;

=cut

foreach my $t (@rev_iter_tests) {
    $t->($it);
}

# seeking
my $node;
$it = $tree->iter('France');
$node = $it->next;
is($node->key, 'France', 'seek check, key exists');

$it = $tree->iter('Iceland');
$node = $it->next;
is($node->key, 'Ireland', 'seek check, key does not exist but is lt max key');

$it = $tree->iter('Timbuktu');
$node = $it->next;
ok(!defined $node, 'seek check, non existant key gt all keys')
  or diag(Dumper($node));

# seeking in reverse
$it = $tree->rev_iter('Hungary');
$node = $it->next;
is($node->key, 'Hungary', 'reverse seek check, key exists');
$node = $it->next;
is($node->key, 'Germany', 'reverse seek check, next key lt this one');

$it = $tree->rev_iter('Finland');
$node = $it->next;
is($node->key, 'England', 'reverse seek check, key does not exist but is gt min key');

$it = $tree->rev_iter('Albania');
$node = $it->next;
ok(!defined $node, 'reverse seek check, non existant key lt all keys');

$tree->put('Timbuktu' => '');
is($tree->get('Timbuktu'), '', 'False values can be stored');
__END__ 
