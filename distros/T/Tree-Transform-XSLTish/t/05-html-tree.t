#!perl
package HtmlTransform;{
 use Tree::Transform::XSLTish ':engine';
 use strict;
 use warnings;

 engine_class 'XML::XPathEngine';

 default_rules;

 tree_rule match => 'img[@alt="pick"]', action => sub {
     return $_[0]->it->findvalue('@src');
 };

}

package main;
use Test::Most 'die';
use strict;
use warnings;
eval 'use XML::XPathEngine;use HTML::TreeBuilder::XPath 0.10;';
plan skip_all => 'XML::XPathEngine and HTML::TreeBuilder::XPath 0.10 needed for this test' if $@;
plan tests=> 1;

my $tree=HTML::TreeBuilder::XPath->new();
$tree->parse(<<'HTML');$tree->eof;
<html>
 <body>
  <p>test</p>
  <img src="nothing" />
  <img src="this one" alt="pick" />
 </body>
</html>
HTML

{
my $trans=HtmlTransform->new();
my @results=$trans->transform($tree);
is_deeply \@results,['this one'],'HTML example';
}
