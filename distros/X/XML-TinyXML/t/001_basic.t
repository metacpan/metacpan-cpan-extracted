# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl TinyXML.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use strict;
use Test::More tests => 14;
BEGIN { use_ok('XML::TinyXML') };

my $fail = 0;
foreach my $constname (qw(
	XML_BADARGS XML_GENERIC_ERR XML_LINKLIST_ERR XML_MEMORY_ERR XML_NOERR
	XML_OPEN_FILE_ERR XML_PARSER_GENERIC_ERR XML_UPDATE_ERR XML_BAD_CHARS
        XML_MROOT_ERR XML_NODETYPE_COMMENT XML_NODETYPE_SIMPLE XML_NODETYPE_CDATA)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined XML::TinyXML macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################

my $txml = XML::TinyXML->new();
$txml->allowMultipleRootNodes(0);
$txml->loadFile("./t/t.xml");
is($txml->countChildren('/parent'), 3);
my $node;
ok ($node = $txml->getNode('/parent'));
is($txml->countChildren($node), 3);
is($txml->countChildren($node->{_node}), 3);

$node = $txml->getNode('/qtest');
use Data::Dumper;
my $attributes = $node->attributes;
#warn Dumper($attributes);

$txml->addRootNode('xml2');
is($txml->countRootNodes, 1);
$txml->allowMultipleRootNodes(1);
$txml->addRootNode('xml2');
is($txml->countRootNodes, 2);
# test array context
my @array = $txml->rootNodes;
is(scalar(@array), 2);

# test scalar context
my $ref = $txml->rootNodes;
is(ref($ref), "ARRAY");
is(scalar(@$ref), 2);

# can we remove an entire branch ?
$txml->removeRootNode(0);
is($txml->countRootNodes, 1);

# test switching ALLOW_MULTIPLE_ROOTNODES again
$txml->allowMultipleRootNodes(0);
my $rc = $txml->addRootNode('xml2');
is($rc, XML_MROOT_ERR);
is($txml->countRootNodes, 1);

