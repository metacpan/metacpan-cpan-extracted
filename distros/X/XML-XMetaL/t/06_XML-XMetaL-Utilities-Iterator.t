# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 06_XML_XML-XMetaL-Utilities.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;

BEGIN {
    use lib ('lib', '../lib');
    use_ok('XML::XMetaL::Factory');
    use_ok('XML::XMetaL::Utilities::Filter::Element');
    use_ok('XML::XMetaL::Utilities::Iterator');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use constant TRUE  => 1;
use constant FALSE => 0;

my $xmetal;
SET_UP: {
    my $xml = join "", <DATA>;
    my $factory = XML::XMetaL::Factory->new($xml);
    $xmetal = $factory->create_xmetal($xml);
    
}

my $iterator;
CONSTRUCTOR: {
    my $document_element = $xmetal->{ActiveDocument}->{documentElement};
    my $filter = XML::XMetaL::Utilities::Filter::Element->new();
    $iterator = XML::XMetaL::Utilities::Iterator->new(-domnode => $document_element,
                                                      -filter  => $filter);
}

HASNEXT1: {
    ok(eval{$iterator->has_next()}, "has_next() test 1");
}

NEXT: {
    my @elements = qw(Article Title Sect1 Title Para);
    my $current_node;
    my $result = FALSE;
    while ($current_node = $iterator->next()) {
        if ($current_node->{tagName} eq  shift @elements) {
            $result = TRUE;
        } else {
            $result = FALSE;
            last;
        };
    }
    ok($result, "next() test");
}


HASNEXT2: {
    ok(eval{!$iterator->has_next()}, "has_next() test 2");
}

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