# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 06_XML_XML-XMetaL-Utilities.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 32;

BEGIN {
    use lib ('lib', '../lib');
    use_ok('XML::XMetaL::Mock::DOMElement');
    use_ok('XML::XMetaL::Mock::DOMNodeList');
    use_ok('XML::XMetaL::Mock::DOMText');
    use_ok('XML::XMetaL::Utilities::Filter::All');
    use_ok('XML::XMetaL::Utilities::Filter::Element');
    use_ok('XML::XMetaL::Utilities::Filter::Text');
    use_ok('XML::XMetaL::Utilities::Iterator');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Data::Dumper;

use constant TRUE  => 1;
use constant FALSE => 0;

my $root_node;
my $child_node_02;
my $child_node_03;
my $child_node_04;

SET_UP: {
        $root_node = XML::XMetaL::Mock::DOMElement->new(
            nodeID => 'node01'
        );
        $child_node_02 = XML::XMetaL::Mock::DOMText->new(
            nodeID => 'node02'
        );
        $root_node->appendChild($child_node_02);
        
        $child_node_03 = XML::XMetaL::Mock::DOMElement->new(
            nodeID => 'node03'
        );
        $root_node->appendChild($child_node_03);
        
        $child_node_04 = XML::XMetaL::Mock::DOMText->new(
            nodeID => 'node04'
        );
        $child_node_03->appendChild($child_node_04);
}


my $filter = XML::XMetaL::Utilities::Filter::All->new();

BASIC_TEST: {
    my $iterator = XML::XMetaL::Utilities::Iterator->new(-domnode => $root_node,
                                                      -filter  => $filter);
    ok(eval{$iterator->has_next()}, "has_next() test 1");

    my @node_id = qw(node01 node02 node03 node04);
    my $current_node;
    my $result = FALSE;
    while ($current_node = $iterator->next()) {
        if ($current_node->{nodeID} eq  shift @node_id) {
            $result = TRUE;
        } else {
            $result = FALSE;
            last;
        };
        ok($result, "next() test");
    }
    is(scalar(@node_id), 0, "Checking for nodes not yet traversed: ".scalar(@node_id).": @node_id");
    ok(eval{!$iterator->has_next()}, "has_next() test 2");
}

my $child_node_05;
my $child_node_06;

TEST02: {
    $child_node_05 = XML::XMetaL::Mock::DOMElement->new(
            nodeID => 'node05'
        );
    $child_node_03->appendChild($child_node_05);
    
    $child_node_06 = XML::XMetaL::Mock::DOMElement->new(
            nodeID => 'node06'
        );
    $root_node->appendChild($child_node_06);
    
    my $iterator = XML::XMetaL::Utilities::Iterator->new(
        -domnode => $child_node_03,
        -filter  => $filter
    );
    ok(eval{$iterator->has_next()}, "has_next() test 3");

    my @node_id = qw(node03 node04 node05);
    my $current_node;
    my $result = FALSE;
    while ($current_node = $iterator->next()) {
        if ($current_node->{nodeID} eq  shift @node_id) {
            $result = TRUE;
        } else {
            $result = FALSE;
            last;
        };
        ok($result, "next() test");
    }
    is(scalar(@node_id), 0, "Checking for nodes not yet traversed: ".scalar(@node_id).": @node_id");
    ok(eval{!$iterator->has_next()}, "has_next() test 4");
}

TEST03: {
    my $element_filter = XML::XMetaL::Utilities::Filter::Element->new();
    my $iterator = XML::XMetaL::Utilities::Iterator->new(
        -domnode => $root_node,
        -filter  => $element_filter
    );
    ok(eval{$iterator->has_next()}, "has_next() test 5");

    my @node_id = qw(node01 node03 node05 node06);
    my $current_node;
    my $result = FALSE;
    while ($current_node = $iterator->next()) {
        if ($current_node->{nodeID} eq  shift @node_id) {
            $result = TRUE;
        } else {
            $result = FALSE;
            last;
        };
        ok($result, "next() test");
    }
    is(scalar(@node_id), 0, "Checking for nodes not yet traversed: ".scalar(@node_id).": @node_id");
    ok(eval{!$iterator->has_next()}, "has_next() test 6");

}

TEST04: {
    my $text_node_filter = XML::XMetaL::Utilities::Filter::Text->new();
    my $iterator = XML::XMetaL::Utilities::Iterator->new(
        -domnode => $root_node,
        -filter  => $text_node_filter
    );
    ok(eval{$iterator->has_next()}, "has_next() test 7");

    my @node_id = qw(node02 node04);
    my $current_node;
    my $result = FALSE;
    while ($current_node = $iterator->next()) {
        if ($current_node->{nodeID} eq  shift @node_id) {
            $result = TRUE;
        } else {
            $result = FALSE;
            last;
        };
        ok($result, "next() test");
    }
    is(scalar(@node_id), 0, "Checking for nodes not yet traversed: ".scalar(@node_id).": @node_id");
    ok(eval{!$iterator->has_next()}, "has_next() test 8");

}

#diag(Dumper($root_node));

__DATA__
<?xml version="1.0"?>
<!DOCTYPE Article PUBLIC "-//SoftQuad Software//DTD Journalist v2.0 20000501//EN" "journalist.dtd">
<Article> 
  <Title>Test Document</Title>
  <Sect1> 
	 <Title>Iterator Test</Title>
	 <Para>The test iterates over all elements</Para> 
  </Sect1> 
</Article> 