#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use XML::LibXML;

use XML::XPath::Helper::Const qw(:all);

{
  my $dom = XML::LibXML->load_xml(string => <<'EOT');
   <root>
     <findthis>
       <entry>a</entry>
       <entry>b</entry>
       <entry>c</entry>
     </findthis>
     <ignorethis>
       <foo>a</foo>
       <bar>b</bar>
     </ignorethis>
     <ignorethat>
       <child>
         <childofchild></childofchild>
       </child>
     </ignorethat>
     <simpletag>blah</simpletag>
   </root>
EOT
  {
    note("XPATH_SIMPLE_LIST");
    my @nodes = $dom->documentElement->findnodes(XPATH_SIMPLE_LIST);
    is(@nodes, 1, "Found 1 node");
    is($nodes[0]->nodeName, 'findthis', 'Correct node!');
  }
  {
    note("XPATH_SIMPLE_TAGS");
    my @nodes = $dom->documentElement->findnodes(XPATH_SIMPLE_TAGS);
    is(@nodes, 1, "Found 1 node");
    is($nodes[0]->nodeName, 'simpletag', 'Correct node!');
  }
}

{
  note("XPATH_NESTED_TAGS");
  my $dom = XML::LibXML->load_xml(string => <<'EOT');
   <root>
     <list>
       <entry>a</entry>
       <entry>b</entry>
       <entry>c</entry>
     </list>
     <simpletag>blah</simpletag>
   </root>
EOT
  {
    my @nodes = $dom->documentElement->findnodes(XPATH_NESTED_TAGS);
    is(@nodes, 1, "Found 1 node");
    is($nodes[0]->nodeName, 'list', 'Correct node!');
  }
}


#-----------------------------------------------------------------------------
done_testing();


