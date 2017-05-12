#!perl
package main;
use Test::Most 'die';
BEGIN {
    eval 'use XML::LibXML;use XML::LibXML::XPathContext;';
    plan skip_all => 'XML::LibXML and XML::LibXML::XPathContext needed for this test' if $@;
}

package XmlTransform;{
 use Tree::Transform::XSLTish ':engine';
 use strict;
 use warnings;

 engine_class 'XML::LibXML::XPathContext';

 default_rules;

 tree_rule match => 'img[@alt="pick"]', action => sub {
     return $_[0]->it->findvalue('@src');
 };

}

package NSXmlTransform;{
 use Tree::Transform::XSLTish ':engine';
 use XML::LibXML::XPathContext;
 use strict;
 use warnings;

 engine_factory {
     my $e=XML::LibXML::XPathContext->new();
     $e->registerNs('t','http://test/');
     return $e;
 };

 default_rules;

 tree_rule match => 't:img[@alt="pick"]', action => sub {
     return $_[0]->it->findvalue('@src');
 };

}

package main;
use strict;
use warnings;
plan tests=>2;

{
my $tree=XML::LibXML->new->parse_string(<<'XML');
<html>
 <body>
  <p>test</p>
  <img src="nothing" />
  <img src="this one" alt="pick" />
 </body>
</html>
XML

my $trans=XmlTransform->new();
my @results=$trans->transform($tree);
is_deeply \@results,['this one'],'XML example';
}

{
my $tree=XML::LibXML->new->parse_string(<<'XML');
<html xmlns:x="http://test/">
 <body>
  <p>test</p>
  <img src="nothing" />
  <img src="NOT this one" alt="pick" />
  <x:img src="this one" alt="pick" />
 </body>
</html>
XML

my $trans=NSXmlTransform->new();
my @results=$trans->transform($tree);
is_deeply \@results,['this one'],'XML namespaces';
}
