# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN {
    use lib ('lib', '../lib');
    use_ok('XML::XMetaL');
    use_ok('XML::XMetaL::Factory');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

package XML::XMetaL::Custom::Journalist;

use base qw(XML::XMetaL::Base);

sub get_class {return ref $_[0]}

package XML::XMetaL::Custom::Test;

use base qw(XML::XMetaL::Base);

sub get_class {return ref $_[0]}

package main;

my $dispatcher1;
my $xmetal;

SET_UP: {
    eval {
        my $factory = XML::XMetaL::Factory->new();
        my $test_doc1 = q{<?xml version="1.0"?>
    <!DOCTYPE Article PUBLIC "-//SoftQuad Software//DTD Journalist v2.0 20000501//EN" "journalist.dtd">
    <Article> 
        <Title>XMetaL Test Document</Title>
        <Sect1> 
            <Title>Section</Title>
            <Para>First paragraph</Para>
            <Para>Second paragraph</Para> 
        </Sect1> 
    </Article>};
        
        my $test_doc2 = q{<?xml version="1.0"?>
    <!DOCTYPE test [<!ELEMENT test (#PCDATA)*>]>
    <test>A test text</test>};
    
        $xmetal = $factory->create_xmetal($test_doc1);
        $dispatcher1 = XML::XMetaL->new(-application => $xmetal);
    };
    diag($@) if $@;
}

CONSTRUCTOR: {
    is(eval{ref($dispatcher1)},
       "XML::XMetaL",
       "XML::XMetaL constructor test");
}

SINGLETON: {
    my $dispatcher2;
    eval {
        $dispatcher2 = XML::XMetaL->new(-application => $xmetal);
    };
    diag($@) if $@;
    is($dispatcher1,$dispatcher2, "XML::XMetaL singleton test");
}

GET_HANDLER: {
    my %handlers;
    eval {
        my $journalist_handler = XML::XMetaL::Custom::Journalist->new(-application => $xmetal);
        my $test_handler = XML::XMetaL::Custom::Test->new(-application => $xmetal);
        $dispatcher1->add_handler(
                                  -system_identifier  => "journalist.dtd",
                                  -handler            => $journalist_handler
        );
        $dispatcher1->add_handler(
                                  -system_identifier  => "http://no_such_server/test.dtd",
                                  -handler            => $test_handler
        );
    };
    diag($@) if $@;
    is(eval{ref $dispatcher1->get_handler("journalist.dtd")},
       "XML::XMetaL::Custom::Journalist",
       "add_handler() and get_handler() test"
    );
}

DISPATCHER: {
    my $class = eval{$dispatcher1->get_class()};
    is($class,
       "XML::XMetaL::Custom::Journalist",
       "AUTOLOAD dispatch test"
    );
}