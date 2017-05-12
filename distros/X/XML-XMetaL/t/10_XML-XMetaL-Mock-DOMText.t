# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN {
    use lib ('lib', '../lib');
    use_ok('XML::XMetaL::Mock::DOMText');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $dom_text;

SET_UP: {
    eval {
        $dom_text = XML::XMetaL::Mock::DOMText->new(nodeID => 'node01');
    };
    diag($@) if $@;
    is(eval{ref $dom_text},
       "XML::XMetaL::Mock::DOMText",
       "XML::XMetaL::Mock::DOMText constructor test"
    );
}

LENGTH: {
    my $string = "test string";
    eval {
        $dom_text->{data} = $string;
    };
    diag($@) if $@;
    is(
        eval {$dom_text->{length}},
        11,
        "data and length property test 1"
    );
    diag($@) if $@;
    
    $string = "Other test string";
    eval {
        $dom_text->{data} = $string;
    };
    diag($@) if $@;
    is(
        eval {$dom_text->{length}},
        17,
        "data and length property test 2"
    );
    diag($@) if $@;
}

