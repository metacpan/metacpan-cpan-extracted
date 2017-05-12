# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN {
    use lib ('lib', '../lib');
    use_ok('XML::XMetaL::Mock::DOMELement');
    use_ok('XML::XMetaL::Mock::DOMNodeList');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $dom_node_list;

SET_UP: {
    eval {
        $dom_node_list = XML::XMetaL::Mock::DOMNodeList->new(
            map {
                XML::XMetaL::Mock::DOMElement->new(
                    nodeID  => $_,
                )
            } qw(node01 node02)
        );
    };
    diag($@) if $@;
    is(eval{ref $dom_node_list},
       "XML::XMetaL::Mock::DOMNodeList",
       "XML::XMetaL::Mock::DOMNodeList constructor test"
    );
}

ITEM: {
    eval {
        $dom_node_list->add(
            map {XML::XMetaL::Mock::DOMElement->new(nodeID => $_)} qw(node03 node04)
        );
        my $item;
        my $index = 0;
        foreach my $node_id (qw(node01 node02 node03 node04)) {
            $item = $dom_node_list->item($index);
            is($item->{nodeID},
               $node_id,
               "item() test"
            );
            $index++;
        }
        
    };
    diag $@ if $@;
}

LENGTH: {
    is(eval {$dom_node_list->{length}},
       4,
       "length property test"
    );
}