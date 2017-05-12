# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN {
    use lib ('lib', '../lib');
    use_ok('XML::XMetaL::Factory');
};


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

LOAD_FROM_STRING: {
    my ($factory,$xmetal);
    my $xml = '<?xml version="1.0"?>
    <!DOCTYPE Article PUBLIC "-//SoftQuad Software//DTD Journalist v2.0 20000501//EN" "journalist.dtd">
    <Article> 
      <Title>XMetaL Test Document</Title>
      <Sect1> 
         <Title>Section</Title>
         <Para>First paragraph</Para>
         <Para>Second paragraph</Para> 
      </Sect1> 
    </Article> ';
    is(eval{ref($factory = XML::XMetaL::Factory->new())},
       "XML::XMetaL::Factory",
       "XML::XMetaL::Factory constructor test");
    
    is(eval{ref($xmetal = $factory->create_xmetal($xml))},
       "Win32::OLE",
       "create_xmetal() using string");
    
    my $title_string;
    eval {
        my $active_document = $xmetal->{ActiveDocument};
        my $title_nodelist = $active_document->getElementsByTagName('Title');
        my $title_elm = $title_nodelist->item(0);
        my $child_nodelist = $title_elm->childNodes();
        my $node_count =  $child_nodelist->{length};
        for (my $i=0; $i < $node_count; $i++) {
            $title_string .= $child_nodelist->item($i)->{nodeValue};
        }
    };
    diag($@) if $@;
    is($title_string,"XMetaL Test Document","create_xmetal() test 2");
    undef $xmetal;
    undef $factory;
}

GET_XMETAL_PATH: {
    my $factory = XML::XMetaL::Factory->new();
    my $path = $factory->get_xmetal_path();
    if ($path) {
        pass("get_xmetal_path() test");
    } else {
        fail("get_xmetal_path() test");
    }
}

