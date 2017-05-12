# vim: filetype=perl
use strict;

use XML::LibXML;
use XML::SAX::PurePerl;

our @doc;
BEGIN {
  @doc = (qw(
    #document html head title head body h1 body html
  ));
}

use Test::More tests => @doc + 4;

use_ok("XML::SAX::IncrementalBuilder::LibXML");

my $b = XML::SAX::IncrementalBuilder::LibXML->new(godepth => 2, detach => 0);
my $p = XML::LibXML->new(Handler => $b);
#my $p = XML::SAX::PurePerl->new(Handler => $b);

$p->parse_string(join('', <DATA>));
#while (my $line = <DATA>) {
#  $p->parse_chunk($line);
#}

is($b->finished_nodes, @doc, 'got just enough nodes');

my $rootname = shift @doc;
my $root = $b->get_node;

is ($root->nodeName, $rootname, "got $rootname");

TODO: {
  local $TODO = 'XML::LibXML::SAX::Builder has a buggy start_dtd';
  isa_ok($root->externalSubset, 'XML::LibXML::Dtd', 'external subset');
}

is ($root->getEncoding, 'ISO-8859-1', 'got the right encoding');

foreach my $node (@doc) {
        is ($b->get_node->nodeName, $node, 'got expected node');
}

__DATA__
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
  <head>
    <title>FOO</title>
  </head>
  <body>
    <h1>FOO</h1>
  </body>
</html>
