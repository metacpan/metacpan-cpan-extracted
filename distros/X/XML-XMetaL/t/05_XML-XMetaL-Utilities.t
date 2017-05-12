# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 06_XML_XML-XMetaL-Utilities.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 43;

BEGIN {
    use lib ('lib', '../lib');
    use_ok('XML::XMetaL::Factory');
    if(require XML::XMetaL::Utilities) {
        import XML::XMetaL::Utilities qw(:all);
        pass("use XML::XMetaL::Utilities test");
    } else {
        fail("use XML::XMetaL::Utilities test");
    }
    use_ok('XML::XMetaL::Utilities::Iterator');
    use_ok('XML::XMetaL::Utilities::Filter::All');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use constant TRUE  => 1;
use constant FALSE => 0;

my $xmetal;
SET_UP: {
    my $xml = join "", <DATA>;
    my $test = XML::XMetaL::Factory->new($xml);
    $xmetal = $test->create_xmetal($xml);
}

CONSTANTS: {
    diag("Testing constants exported using the :all tag");
    eval {
        my $document = $xmetal->{ActiveDocument};
        my $node;
        $node = $document->createElement('Para');
        is(DOMELEMENT(),eval{$node->{nodeType}}, "DOMELEMENT constant test");
        
        $node = $document->createAttribute('Id');
        is(DOMATTR(),            eval{$node->{nodeType}}, "DOMATTR constant test");
        
        $node = $document->createTextNode('Dummy text');
        is(DOMTEXT(),            eval{$node->{nodeType}}, "DOMTEXT constant test");
        
        $node = $document->createCDATASection('Dummy text');
        is(DOMCDATASECTION(),    eval{$node->{nodeType}}, "DOMCDATASECTION constant test");
        
        $document->DeclareTextEntity('testEntity','Dummy entity text');
        $node = $document->{doctype}->{entities}->getNamedItem('testEntity');
        is(DOMENTITY(),          eval{$node->{nodeType}}, "DOMENTITY constant test");
        
        $node = $document->createEntityReference('testEntity');
        is(DOMENTITYREFERENCE(), eval{$node->{nodeType}}, "DOMENTITYREFERENCE constant test");
        
        $node = $document->createProcessingInstruction('tstPI', 'testdata');
        is(DOMPROCESSINGINSTRUCTION(), eval{$node->{nodeType}}, "DOMPROCESSINGINSTRUCTION constant test");
        
        $node = $document->createComment('Dummy comment text');
        is(DOMCOMMENT(), eval{$node->{nodeType}}, "DOMCOMMENT constant test");
        
        is(DOMDOCUMENT(), eval{$document->{nodeType}}, "DOMDOCUMENT constant test");
        
        $node = $document->{doctype};
        is(DOMDOCUMENTTYPE(), eval{$node->{nodeType}}, "DOMDOCUMENTTYPE constant test");
        
        $node = $document->createDocumentFragment();
        is(DOMDOCUMENTFRAGMENT(), eval{$node->{nodeType}}, "DOMDOCUMENTFRAGMENT constant test");
        
        is(DOMNOTATION(), 12, "DOMNOTATION constant test");
        
        is(DOMCHARACTERREFERENCE(), 505, "DOMCHARACTERREFERENCE constant test");

        is(UNKNOWN(),       -1, "UNKNOWN constant test"); 
        is(CDATA(),          0, "CDATA constant test"); 
        is(ID(),             1, "ID constant test");
        is(IDREF(),          2, "IDREF constant test"); 
        is(IDREFS(),         3, "IDREFS constant test"); 
        is(ENTITY(),         4, "ENTITY constant test");
        is(ENTITIES(),       5, "ENTITIES constant test");
        is(NMTOKEN(),        6, "NMTOKEN constant test");
        is(NMTOKENS(),       7, "NMTOKENS constant test");
        is(NOTATION(),       8, "NOTATION constant test");
        is(NAMETOKENGROUP(), 9, "NAMETOKENGROUP constant test");

    };
    diag($@) if $@;
}


my $utilities;
CONSTRUCTOR: {
    eval {
        $utilities = XML::XMetaL::Utilities->new(-application => $xmetal);
    };
    diag($@) if $@;
    is(eval{ref($utilities)},
       "XML::XMetaL::Utilities",
       "XML::XMetaL::Utilities constructor test"
    )
}

GET_APPLICATION: {
    my $application = eval{$utilities->get_application()};
    is($application,
       $xmetal,
       "get_application() test"
      )
}

GET_ACTIVE_DOCUMENT: {
    my $active_document = eval{$utilities->get_active_document()};
    my $filter = XML::XMetaL::Utilities::Filter::All->new();
    my $iterator1 = XML::XMetaL::Utilities::Iterator->new(
                    -domnode => $active_document->{documentElement},
                    -filter  => $filter);
    my $iterator2 = XML::XMetaL::Utilities::Iterator->new(
                    -domnode => $xmetal->{ActiveDocument}->{documentElement},
                    -filter  => $filter);
    my $compare;
    my $node1;
    my $node_name1;
    my $node2;
    my $node_name2;
    while (($node1 = $iterator1->next()) &&
           ($node2 = $iterator2->next())) {
        $node_name1 = $node1->{nodeName};
        $node_name2 = $node2->{nodeName};
        $compare = $node_name1 eq $node_name2 ? TRUE : FALSE;
        last unless $compare;
    }
    ok($compare, "get_active_document() test");
}

GET_SELECTION: {
    is(eval{ref $utilities->get_selection()},
       "Win32::OLE",
       "get_selection() test"
      );
    diag($@) if $@;
}

GENERATE_ID: {
    my ($id, $old_id);
    eval {
        for (my $count = 0; $count < 1000; $count++) {
            $id = XML::XMetaL::Utilities->generate_id();
            die("New id was less than or equal to old id")
                unless $id gt $old_id;
            $old_id = $id;
        }
    };
    if ($@) {
        diag($@);
        fail("generate_id() class method test");
    } else {
        pass("generate_id() class method test");
    }
}

GET_ID_ATTRIBUTE_NAME: {
    is(eval{$utilities->get_id_attribute_name('Para')},
       'Id',
       "get_id_attribute_name() test 1"
      );
    is(eval{$utilities->get_id_attribute_name('Annotation')},
       undef,
       "get_id_attribute_name() test 2"
      );
    is(eval{$utilities->get_id_attribute_name('NoSuchElement')},
       undef,
       "get_id_attribute_name() test 3"
      );
}

POPULATE_ELEMENT_WITH_ID: {
    my $paragraph_id;
    eval {
        my $node_list = $xmetal->{ActiveDocument}->getElementsByTagName('Para');
        my $paragraph = $node_list->item(0);
        $utilities->populate_element_with_id($paragraph);
        $paragraph_id = $paragraph->getAttribute('Id');
    };
    diag($@) if $@;
    like($paragraph_id,
         qr/\d+$/,
         "populate_element_with_id() test"
        );
}

POPULATE_ID_ATTRIBUTES: {
    my $article_id;
    my $sect1_id;
    eval {
        $utilities->populate_id_attributes('Article');
        my $article = $xmetal->{ActiveDocument}->{documentelement};
        $article_id = $article->getAttribute('Id');
        $utilities->populate_id_attributes('Sect1');
        my $node_list = $xmetal->{ActiveDocument}->getElementsByTagName('Sect1');
        $sect1_id = $node_list->item(0)->getAttribute('Id');
    };
    diag($@) if $@;
    like($article_id,
         qr/\d+$/,
         "populate_id_attributes() test 1"
        );
    like($sect1_id,
         qr/\d+$/,
         "populate_id_attributes() test 2"
        );
}

WORD_COUNT: {
    do {
        my $string = "This is a word count test.";
        my $word_count = eval {$utilities->word_count($string)};
        diag($@) if $@;
        is($word_count,
           6,
           "word_count(\$string) test"
          );
    };
    do {
        my $node_list = $xmetal->{ActiveDocument}->getElementsByTagName('Sect1');
        my $paragraph = $node_list->item(0);
        my $word_count = eval {$utilities->word_count($paragraph)};
        diag($@) if $@;
        is($word_count,
           12,
           "word_count(\$element_node) test"
          );
    };
}

INSERT_ELEMENT_WITH_ID: {
    my $node_list = $xmetal->{ActiveDocument}->getElementsByTagName('Para');
    my $paragraph = $node_list->item(0);
    my $selection = $xmetal->{Selection};
    $selection->SelectAfterNode($paragraph);
    my $variable_list_node = $utilities->insert_element_with_id('VariableList');
    is(eval{$variable_list_node->{nodeName}},
       'VariableList',
       "insert_element_with_id() test (checking element name)"
      );
    like(eval {$variable_list_node->getAttribute('Id')},
         qr/\d+$/,
         "insert_element_with_id() test (checking Id attribute)"
      );
}


__DATA__
<?xml version="1.0"?>
<!DOCTYPE Article PUBLIC "-//SoftQuad Software//DTD Journalist v2.0 20000501//EN" "journalist.dtd">
<Article> 
  <Title>Test Document</Title>
  <Sect1> 
	 <Title>Word Count Test</Title>
	 <Para>All the words in this section will be counted.</Para> 
  </Sect1> 
</Article> 