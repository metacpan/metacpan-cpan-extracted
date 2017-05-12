use strict;
use warnings;

use Test::More tests => 39;
use Test::Exception;

BEGIN {
    use_ok('Tree::Binary::Visitor::Base');
    use_ok('Tree::Binary::VisitorFactory');
    use_ok('Tree::Binary::Visitor::PreOrderTraversal');
    use_ok('Tree::Binary::Visitor::PostOrderTraversal');
    use_ok('Tree::Binary::Visitor::InOrderTraversal');
    use_ok('Tree::Binary::Visitor::BreadthFirstTraversal');
}

can_ok("Tree::Binary::Visitor::Base", 'new');

my $base = Tree::Binary::Visitor::Base->new();
isa_ok($base, 'Tree::Binary::Visitor::Base');

# test base abstract method

can_ok($base, 'visit');

throws_ok {
    $base->visit();
} qr/Method Not Implemented/, '... this should die';

# test node filter accessors and mutators

can_ok($base, 'setNodeFilter');
can_ok($base, 'getNodeFilter');
can_ok($base, 'clearNodeFilter');

throws_ok {
    $base->setNodeFilter()
} qr/Insufficient Arguments/, '... this should die';

throws_ok {
    $base->setNodeFilter("Fail")
} qr/Insufficient Arguments/, '... this should die';

throws_ok {
    $base->setNodeFilter([])
} qr/Insufficient Arguments/, '... this should die';

my $test_sub = sub { "Test" };

$base->setNodeFilter($test_sub);
is($base->getNodeFilter(), $test_sub, '... we have the right node filter');
is($base->getNodeFilter()->(), 'Test', '... we have the right node filter');

$base->clearNodeFilter();
ok(!defined($base->getNodeFilter()), '... our node filter is now undefined');

# test VisitorFactory and Visitor exceptions

can_ok("Tree::Binary::VisitorFactory", 'new');

my $visitor_factory = Tree::Binary::VisitorFactory->new();
isa_ok($visitor_factory, 'Tree::Binary::VisitorFactory');

throws_ok {
    $visitor_factory->get("FakeVisitor")
} qr/Illegal Operation/, '... this should die';

throws_ok {
    $visitor_factory->getVisitor()
} qr/Insufficient Arguments/, '... this should die';

foreach my $visitor_class (qw(
                        PreOrderTraversal
                        PostOrderTraversal
                        InOrderTraversal
                        BreadthFirstTraversal
                    )) {
    my $visitor = $visitor_factory->get($visitor_class);
    throws_ok {
        $visitor->visit()
    } qr/Insufficient Arguments/, '... this should die';
    throws_ok {
        $visitor->visit("Fail")
    } qr/Insufficient Arguments/, '... this should die';
    throws_ok {
        $visitor->visit([])
    } qr/Insufficient Arguments/, '... this should die';
    throws_ok {
        $visitor->visit(bless({}, 'Fail'))
    } qr/Insufficient Arguments/, '... this should die';
}

