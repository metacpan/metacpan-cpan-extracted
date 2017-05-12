use Test::More tests => 2;

#
# this tests a bug present in 0.09 on perl 5.10 only which
# cuased the parse stack to become undefined during the
# parse.
#

use XML::Parser::Lite::Tree;
my $x = XML::Parser::Lite::Tree->instance();

my $tree = $x->parse('<aaa id="a1"><bbb id="b1" /><ccc id="c1" /><bbb id="b2" /><ddd><bbb id="b3" /></ddd><ccc id="c2" /></aaa>');

# has a root element called 'aaa' with 5 children
is($tree->{children}->[0]->{name}, "aaa");
is(scalar @{$tree->{children}->[0]->{children}}, 5);
