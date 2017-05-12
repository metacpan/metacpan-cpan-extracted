# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN {
    use lib ('lib', '../lib');
    use_ok('XML::XMetaL::Mock::DOMElement');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $dom_element;

SET_UP: {
    eval {
        $dom_element = XML::XMetaL::Mock::DOMElement->new(
            nodeID  => 'node01',
            tagName => 'book',
        );
    };
    diag($@) if $@;
    is(eval{ref $dom_element},
       "XML::XMetaL::Mock::DOMElement",
       "XML::XMetaL::Mock::DOMElement constructor test"
    );
}

PROPERTIES: {
    is(eval{$dom_element->{nodeID}},
       "node01",
       "nodeID property test (Mock object specific property - inherited from DOMNode)"
    );
    is(eval{$dom_element->{tagName}},
       "book",
       "tagName property test"
    );
}

