use Test::More tests => 9;

use_ok( 'Tree::RB::Node::_Constants' );
diag( "Testing Tree::RB::Node::_Constants $Tree::RB::Node::_Constants::VERSION" );

foreach my $m (qw[
    _PARENT
    _LEFT
    _RIGHT
    _COLOR
    _KEY
    _VAL
    BLACK
    RED
  ])
{
    can_ok('Tree::RB::Node::_Constants', $m);
}