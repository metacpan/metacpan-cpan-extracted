#!/usr/bin/perl
use strict;
use warnings qw(FATAL all NONFATAL misc);

use Data::Dumper;
use Test::More qw(no_plan);

use FindBin;
use lib "$FindBin::Bin/..";

#========================================
#
require_ok('YATT::LRXML::Node');
require_ok('YATT::LRXML::Parser');
my $base = YATT::LRXML::Parser->new;

#========================================
#
{
  my %nsdict;
  my $i = 0;
  foreach my $type (qw(
			text
			comment
			decl_comment
			pi
			entity
			root
			element
			attribute
		     )) {
    my $tree;
    ok(ref($tree = YATT::LRXML::Node->new($type, undef, $type))
       , "$type create tree");
    is $tree->node_type, $i, "$type keeps same enum order";
    is $tree->node_type_name, $type, "$type has same type_name";
    is $tree->node_body, $type, "$type get_body";
  } continue {
    $i++;
  }
}
#========================================

import YATT::LRXML::Node;

is(stringify_node($base->create_node(comment => perl => ' foobar'))
   , q(<!--#perl foobar-->), 'stringify_node(perl) comment');

is(stringify_node($base->create_node(text => undef, 'foobar'))
   , q(foobar), 'stringify_node(perl) text');

is(stringify_node($base->create_node(pi => perl => ' foobar'))
   , q(<?perl foobar?>), 'stringify_node(perl) pi');

is(stringify_node($base->create_node(entity => perl => ':foobar'))
   , q(&perl:foobar;), 'stringify_node(perl) entity');

is(stringify_node($base->create_node(element =>
				     , ['perl', 'foo']
				     , $base->create_node(text => undef, 'ba')
				     , 'r'))
   , q(<perl:foo>bar</perl:foo>), q(<perl:foo>bar</perl:foo>));

# element でない attribute は, node_name に
# (intern しない) 生の文字列を入れる。

# empty element は [element => 1] で create する。

is(stringify_node($base->create_node(element =>
			   , ['perl', 'foo']
			   , $base->create_node([attribute => 2]
						, bar => 'baz')
			   , 'b'
			   , $base->create_node(text => undef, 'ar')
			   , $base->create_node([element => 1]
						, ['perl', 'hoe'])))
   , q(<perl:foo bar="baz">bar<perl:hoe /></perl:foo>)
   , q(<perl:foo bar="baz">bar<perl:hoe /></perl:foo>));

is(stringify_node($base->create_node(element =>
			   , ['perl', 'foo']
			   , $base->create_node([attribute => 1]
						, bar => 'baz')
			   , 'b'
			   , $base->create_node(text => undef, 'ar')
			   , $base->create_node([element => 1]
						, ['perl', 'hoe'])))
   , q(<perl:foo bar='baz'>bar<perl:hoe /></perl:foo>)
   , q(<perl:foo bar='baz'>bar<perl:hoe /></perl:foo>));

#========================================
#
my $att;
$att = $base->create_node([attribute => 0], 'foo' => 'bar');
is node_name($att), 'foo', "attribute name";
is node_body($att), 'bar', "attribute name";
is node_flag($att), 0, "attribute quote flag";
#XXX: ok($att->get_quote_char eq "", "attribute quote char");
is stringify_node($att), q(foo=bar), q(foo=bar);

is stringify_node($base->create_node([attribute => 1]
				     , 'foo' => 'bar'))
  , q(foo='bar'), q(foo='bar');

is stringify_node($base->create_node([attribute => 2]
				     , 'foo' => 'bar'))
  , q(foo="bar"), q(foo="bar");

is stringify_node($base->create_node([attribute => undef]
				     , 'checked'))
  , q(checked), q(checked);

is(stringify_node(($att = $base->create_node
		   ([attribute => $base->quoted_by_element]
		    , ['perl', 'foo'] => 'bar', 'baz')))
   , q(<:perl:foo>barbaz</:perl:foo>), q(<:perl:foo>barbaz</:perl:foo>));

is_deeply [node_children($att)], [qw(bar baz)], 'list attribute->children';

#========================================
#
my @elem = $base->create_attlist
  (' ', 'href', '=', undef, 'foo', undef,
   ' ', 'name', '=', 'bar', undef, undef,
   ' ', 'id', '=', undef, undef, 'baz');

print "elem: ", Dumper(@elem), "\n" if $ENV{VERBOSE};

is scalar(@elem), 3, 'parse_match compose all atts';
my $i = 0;
is stringify_node($elem[$i++]), q(href="foo"), q(href="foo");
is stringify_node($elem[$i++]), q(name='bar'), q(name='bar');
is stringify_node($elem[$i++]), q(id=baz), q(id=baz);

#========================================

sub dumper {
  require Data::Dumper;
  Data::Dumper->new(\@_)->Terse(1)->Indent(0)->Dump;
}

{
  #XXX: Do test.
  require_ok('YATT::LRXML::NodeCursor');
  my $cursor = new YATT::LRXML::NodeCursor
    ($base->create_node([element => 0]
			, ['yatt', 'foo']
			, $base->create_node([attribute => 2]
					     , bar => 'baz')
			, 'b'
			, $base->create_node(text => undef, 'ar')
			, $base->create_node([element => 0]
					     , ['perl', 'hoe'])));
  $cursor = $cursor->open;
  while ($cursor && $cursor->readable) {
    print dumper($cursor->node_type_name, scalar $cursor->path_list
		 , $cursor->node_body), "\n";
    if ($cursor->can_open) {
      print "down: ",
	map {defined $_ ? $_ : "(undef)"}
	  $cursor->node_type_name, '.', $cursor->node_name,"\n";
      $cursor = $cursor->open;
    } else {
      print "leaf: (", $cursor->read, ")\n";
    }
    if (!$cursor->readable && $cursor->can_close) {
      print "up: \n";
      $cursor = $cursor->close;
    }
  }
}
